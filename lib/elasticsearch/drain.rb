##
# Drain documents for all nodes in an AWS AutoScaling Group
#
module Elasticsearch
  class Drain

    # @!attribute [r]
    # The Elasticsearch client object
    attr_reader :client

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
      Nodes.new.nodes
    end

    # Convience method to access {Elasticsearch::Drain::Cluster#cluster}
    #
    # @return [Elasticsearch::API::Cluster] Elasticsearch cluster client
    def cluster
      Cluster.new.cluster
    end

    def drain
      fail 'Cluster is unhealthy' unless cluster.healthy?
      instances = asg.instances # need to get the node objects for the instances in the asg
      puts "Found nodes in AutoScalingGroup: #{instances.join(' ')}"
      fail 'Cluster is unhealthy' unless cluster.healthy?
      asg.min_size(0)
      cluster.drain_nodes(instances)
      nodes = Nodes.new
      nodes.nodes_in_asg(reload: true, instances: instances).each do |instance|
        sleep 30 while cluster.relocating_shards?
        if instance.bytes_stored > 0
          sleep 2
        else
          puts "Removing #{instance} from Elasticsearch cluster and #{asg} AutoScalingGroup"
          fail 'Cluster is unhealthy' unless cluster.healthy?
          #remove_node_from_cluster NYI
          sleep 5 until instance.in_recovery?
          fail 'Cluster is unhealthy' unless cluster.healthy?
          puts 'Sleeping for 1 minute before removing the next node'
          sleep 60
        end
      end
    end
  end
end

require_relative 'drain/autoscaling'
require_relative 'drain/version'
require_relative 'drain/cluster'
require_relative 'drain/nodes'
require_relative 'drain/node'
require_relative 'drain/cli'
require 'logger'
