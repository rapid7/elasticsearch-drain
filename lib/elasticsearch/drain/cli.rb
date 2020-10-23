require 'thor'

module Elasticsearch
  class Drain
    class CLI < ::Thor # rubocop:disable Metrics/ClassLength
      package_name :elasticsearch

      attr_reader :drainer
      attr_accessor :active_nodes

      # rubocop:disable Metrics/LineLength
      desc 'asg', 'Drain all documents from all nodes in an EC2 AutoScaling Group'
      option :host, default: 'localhost:9200'
      option :asg, required: true
      option :region, required: true
      option :nodes, type: :array, desc: 'A comma separated list of node IDs to drain. If specified, the --number option has no effect'
      option :number, type: :numeric, desc: 'The number of nodes to drain'
      option :continue, type: :boolean, default: true, desc: 'Whether to continue draining nodes once the first iteration of --number is complete'
      # rubocop:enable Metrics/LineLength
      def asg # rubocop:disable Metrics/MethodLength
        @drainer = Elasticsearch::Drain.new(options[:host],
                                            options[:asg],
                                            options[:region])

        ensure_cluster_healthy
        @active_nodes = drainer.active_nodes_in_asg

        # If :nodes are specified, :number has no effect
        if options[:nodes]
          say "Nodes #{options[:nodes].join(', ')} have been specified, the --number option has no effect"
          number_to_drain = nil
          currently_draining_nodes = nil
        else
          number_to_drain = options[:number]
          currently_draining_nodes = drainer.cluster.currently_draining('_id')
        end

        # If a node or nodes are specified, only drain the requested node(s)
        @active_nodes = active_nodes.find_all do |n|
          instance_id = drainer.asg.instance(n.ipaddress).instance_id
          options[:nodes].include?(instance_id)
        end if options[:nodes]

        do_exit { say_status 'Complete', 'Nothing to do', :green } if active_nodes.empty?
        say_status 'Found Nodes', "AutoScalingGroup: #{instances(active_nodes)}", :magenta

        until active_nodes.empty?
          ensure_cluster_healthy

          nodes = active_nodes

          # If there are nodes in cluster settings "transient.cluster.routing.allocation.exclude"
          # test if those nodes are still in the ASG. If so, work on them first unless nodes are
          # specified.
          if currently_draining_nodes
            nodes_to_drain = active_nodes.find_all { |n| currently_draining_nodes.split(',').include?(n.id) }

            # If the list of nodes_to_drain isn't empty, we want to set nodes to the list of nodes
            # we've already been working on.
            unless nodes_to_drain.empty?
              nodes = nodes_to_drain

              say_status 'Active Nodes', "Resuming drain process on #{instances(nodes)}", :magenta
            end

            # We should only process currently_draining_nodes once
            currently_draining_nodes = nil
          end

          # If we specify a number but DON'T specify nodes, sample the active_nodes.
          if number_to_drain
            nodes = nodes.sample(number_to_drain.to_i)
            say_status 'Active Nodes', "Sampled #{number_to_drain} nodes and got #{instances(nodes)}", :magenta
          end

          @active_nodes = nodes unless options[:continue]

          drain_nodes(nodes)
          deleted_nodes = remove_nodes(nodes)

          # Remove the drained nodes from the list of active_nodes
          deleted_nodes.each do |deleted_node|
            active_nodes.delete_if { |n| n.id == deleted_node.id }
	  end

          unless active_nodes.empty?
            say_status 'Drain Nodes', "#{active_nodes.length} nodes remaining", :green

            sleep_time = wait_sleep_time
            say_status 'Waiting', "Sleeping for #{sleep_time} seconds before the next iteration", :green
            sleep sleep_time
          end
        end
        say_status 'Complete', 'Draining nodes complete!', :green
      end

      no_tasks do
        def ensure_cluster_healthy
          if drainer.cluster.healthy?
            say_status 'Cluster Health', 'Cluster is healthy', :green
          else
            do_exit(1) { say_status 'Cluster Health', 'Cluster is unhealthy', :red }
          end
        end

        def do_exit(code = 0, &block)
          block.call
          exit code
        end

        def instances(nodes)
          instances = nodes.map(&:ipaddress)
          instances.join(' ')
        end

        def adjusted_min_size(nodes)
          min_size = drainer.asg.min_size
          desired_capacity = drainer.asg.desired_capacity
          desired_min_size = if (desired_capacity - nodes.length) >= min_size # Removing the nodes won't violate the min_size
                               # Reduce the asg min_size proportionally
                               (min_size - nodes.length) <= 0 ? 0 : (min_size - nodes.length)
                             else
                               # Removing the nodes will result in the min_size being violated
                               (desired_capacity - nodes.length) <= 0 ? 0 : (desired_capacity - nodes.length)
                             end
          desired_min_size
        end

        def drain_nodes(nodes)
          drainer.asg.min_size = adjusted_min_size(nodes)
          nodes_to_drain = nodes.map(&:id).join(',')
          say_status 'Drain Nodes', "Draining nodes: #{nodes_to_drain}", :magenta
          drainer.cluster.drain_nodes(nodes_to_drain, '_id')
        end

        def wait_sleep_time
          ips = active_nodes.map(&:ipaddress)
          bytes = drainer.nodes.filter_nodes(ips).map(&:bytes_stored)
          sleep_time = 10
          sleep_time = 30 if bytes.any? { |b| b >= 100_000 }
          sleep_time = 60 if bytes.any? { |b| b >= 1_000_000 }
          sleep_time = 120 if bytes.any? { |b| b >= 10_000_000_000 }
          sleep_time
        end

        def remove_nodes(nodes) # rubocop:disable Metrics/MethodLength
          deleted_nodes = []
          while nodes.length > 0
            sleep_time = wait_sleep_time
            nodes.each do |instance|
              instance = drainer.nodes.filter_nodes([instance.ipaddress], true).first
              unless instance.nil? || instance == 0
                if instance.bytes_stored > 0
                  say_status 'Drain Status', "Node #{instance.ipaddress} has #{instance.bytes_stored} bytes to move", :blue
                  sleep sleep_time
                else
                  next unless remove_node(instance)
                  deleted_nodes.push(nodes.find { |n| n.ipaddress == instance.ipaddress })
                  nodes.delete_if { |n| n.ipaddress == instance.ipaddress }
                  break if nodes.length < 1
                  say_status 'Waiting', 'Sleeping for 1 minute before removing the next node', :green
                  sleep 60
                end
            end
          end
          deleted_nodes
        end

        def remove_node(instance) # rubocop:disable Metrics/MethodLength
          instance_id = drainer.asg.instance(instance.ipaddress).instance_id
          instance.instance_id = instance_id
          say_status(
            'Removing Node',
            "Removing #{instance.ipaddress} from Elasticsearch cluster and #{drainer.asg.asg} AutoScalingGroup",
            :magenta
          )
          sleep 5 unless instance.in_recovery?
          node = "#{instance.instance_id}(#{instance.ipaddress})"
          ensure_cluster_healthy
          say_status 'ASG Remove Node', "Removing node: #{node} from AutoScalingGroup: #{drainer.asg.asg}", :magenta
          drainer.asg.detach_instance(instance.instance_id)
          sleep 2
          ensure_cluster_healthy
          say_status 'Terminate Instance', "Terminating instance: #{node}", :magenta
          instance.terminate
        rescue Errors::NodeNotFound
          false
        end
      end
    end
  end
end
