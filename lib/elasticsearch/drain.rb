##
# Drain documents for all nodes in an AWS AutoScaling Group
#
module Elasticsearch
  class Drain
    # @attribute [r]
    # The Elasticsearch hosts to connect to
    attr_reader :hosts

    # @attribute [r]
    # EC2 Region
    attr_reader :region

    # Sets up the Elasticsearch client
    #
    # @option [String] :hosts ('localhost:9200') The Elasticsearch hosts
    #   to connect to
    # @return [Elasticsearch::Transport::Client] Elasticsearch transport client
    def initialize(hosts = 'localhost:9200', asg = nil, region = nil)
      @hosts = hosts
      @region = region
      @asg_name = asg
    end

    # The Elasticsearch client object
    def client
      return @client unless @client.nil?
      @client = ::Elasticsearch::Client.new(
        hosts: hosts,
        retry_on_failure: true,
        log: true,
        logger: ::Logger.new('es_client.log', 10, 1_024_000)
      )
    end

    # EC2 AutoScaling Client
    def asg
      AutoScaling.new(@asg_name, @region)
    end

    # Convience method to access {Elasticsearch::Drain::Nodes#nodes}
    #
    # @return [Array<OpenStruct>] Array of node objects
    def nodes
      Nodes.new(client, asg)
    end

    # Convience method to access {Elasticsearch::Drain::Cluster#cluster}
    #
    # @return [Elasticsearch::API::Cluster] Elasticsearch cluster client
    def cluster
      Cluster.new(client)
    end

    def active_nodes_in_asg
      instances = asg.instances
      nodes.nodes_in_asg(reload: true, instances: instances)
    end

    def drain
      fail 'Cluster is unhealthy' unless cluster.healthy?
      instances = asg.instances
      nodes_to_drain = nodes.nodes_in_asg(reload: true, instances: instances)
      if nodes_to_drain.empty?
        puts 'Nothing to do'
        exit 0
      else
        puts "Found nodes in AutoScalingGroup: #{instances.join(' ')}"
        fail 'Cluster is unhealthy' unless cluster.healthy?
        puts 'Setting MinSize in AutoScalingGroup to 0'
        asg.min_size(0)
        nodes_to_drain = nodes_to_drain.map(&:id).join(',')
        cluster.drain_nodes(nodes_to_drain, '_id')
      end
      active_nodes = active_nodes_in_asg
      while active_nodes.length > 0
        active_nodes.each do |instance|
          instance_id = asg.instance(instance.ipaddress).instance_id
          instance.instance_id = instance_id

          if instance.bytes_stored > 0
            puts "Node #{instance.ipaddress} has #{instance.bytes_stored} bytes to move"
            puts 'Checking the next node...'
            sleep 2
          else
            puts "Removing #{instance.ipaddress} from Elasticsearch cluster and #{asg.asg} AutoScalingGroup"
            fail 'Cluster is unhealthy' unless cluster.healthy?
            sleep 5 unless instance.in_recovery?

            asg.detach_instance(instance.instance_id)
            fail 'Cluster is unhealthy' unless cluster.healthy?
            instance.terminate
            active_nodes = active_nodes_in_asg
            break if active_nodes.length < 1
            puts 'Sleeping for 1 minute before removing the next node'
            sleep 60
          end
        end
      end
      puts 'All done!'
    end
  end
end

require_relative 'drain/autoscaling'
require_relative 'drain/version'
require_relative 'drain/base'
require_relative 'drain/cluster'
require_relative 'drain/nodes'
require_relative 'drain/node'
require_relative 'drain/cli'
require 'logger'
