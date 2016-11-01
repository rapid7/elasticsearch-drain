require 'thor'

module Elasticsearch
  class Drain
    class CLI < ::Thor
      package_name :elasticsearch

      attr_reader :drainer
      attr_accessor :active_nodes

      desc 'asg', 'Drain all documents from all nodes in an EC2 AutoScaling Group'
      option :host, default: 'localhost:9200'
      option :asg, required: true
      option :region, required: true
      option :nodes
      def asg # rubocop:disable Metrics/MethodLength
        @drainer = Elasticsearch::Drain.new(options[:host],
                                            options[:asg],
                                            options[:region])
        ensure_cluster_healthy
        @active_nodes = drainer.active_nodes_in_asg

        # If a node or nodes are specified, only drain the requested node(s)
        @active_nodes = active_nodes.find_all do |n|
          instance_id = drainer.asg.instance(n.ipaddress).instance_id
          options[:nodes].split(',').include?(instance_id)
        end if options[:nodes]

        do_exit { say_status 'Complete', 'Nothing to do', :green } if active_nodes.empty?
        say_status 'Found Nodes', "AutoScalingGroup: #{instances}", :magenta
        ensure_cluster_healthy
        drain_nodes
        remove_nodes
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

        def instances
          instances = active_nodes.map(&:ipaddress)
          instances.join(' ')
        end

        def adjusted_min_size
          min_size = drainer.asg.min_size
          desired_capacity = drainer.asg.desired_capacity
          if (desired_capacity - active_nodes.length) >= min_size # Removing the active_nodes won't violate the min_size
            # Reduce the asg min_size proportionally
            desired_min_size = (min_size - active_nodes.length) <= 0 ? 0 : (min_size - active_nodes.length)
          else
            # Removing the active_nodes will result in the min_size being violated
            desired_min_size = desired_capacity - active_nodes.length
          end
          desired_min_size
        end

        def drain_nodes
          drainer.asg.min_size = adjusted_min_size
          nodes_to_drain = active_nodes.map(&:id).join(',')
          say_status 'Drain Nodes', "Draining nodes: #{nodes_to_drain}", :magenta
          drainer.cluster.drain_nodes(nodes_to_drain, '_id')
        end

        def remove_nodes # rubocop:disable Metrics/MethodLength
          while active_nodes.length > 0
            active_nodes.each do |instance|
              instance = drainer.nodes.filter_nodes([instance.ipaddress], true).first
              if instance.bytes_stored > 0
                say_status 'Drain Status', "Node #{instance.ipaddress} has #{instance.bytes_stored} bytes to move", :blue
                sleep 2
              else
                next unless remove_node(instance)
                active_nodes.delete_if { |n| n.ipaddress == instance.ipaddress }
                break if active_nodes.length < 1
                say_status 'Waiting', 'Sleeping for 1 minute before removing the next node', :green
                sleep 60
              end
            end
          end
        end

        def remove_node(instance) # rubocop:disable Metrics/MethodLength
          instance_id = drainer.asg.instance(instance.ipaddress).instance_id
          instance.instance_id = instance_id
          say_status(
            'Removing Node',
            "Removing #{instance.ipaddress} from Elasticsearch cluster and #{drainer.asg.asg} AutoScalingGroup",
            :magenta)
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
