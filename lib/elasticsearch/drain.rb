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
