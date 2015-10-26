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
        logger: Logger.new('es_client.log', 10, 1_024_000)
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
      # if [ -z "$ASG_NAME" ]; then
      #     echo "ASG_NAME is missing"
      #     usage
      #     exit 1
      # fi
      #
      # if [ -z "$REGION" ]; then
      #     echo "REGION is missing"
      #     usage
      #     exit 1
      # fi
      #
      # if [ -z "$CLUSTER_HOST" ]; then
      #     echo "CLUSTER_HOST is missing"
      #     usage
      #     exit 1
      # fi
      #
      # cluster_health
      # get_nodes_in_asg
      # echo "Found nodes in ASG: $INSTANCES"
      #
      # cluster_health
      # set_asg_min_size
      #
      # for i in $INSTANCES; do
      #     get_node_ipaddress
      #     NODE=$IP
      #     NODES+="${NODE},"
      # done
      # NODES=${NODES%?}
      #
      # echo "Sleeping 1 minute before starting"
      # sleep 60
      # echo "Draining data from $NODES"
      #
      # for i in $INSTANCES; do
      #     get_node_ipaddress
      #     INSTANCE_ID=$i
      #     NODE=$IP
      #     echo "Removing $NODE from ES cluster and $ASG_NAME AutoScalingGroup"
      #     cluster_health
      #     remove_node_from_cluster
      #     cluster_health
      #     echo "Sleeping for 1 minute before removing the next node"
      #     sleep 60
      # done
    end
  end
end

require_relative 'drain/autoscaling'
require_relative 'drain/version'
require_relative 'drain/cluster'
require_relative 'drain/nodes'
require_relative 'drain/node'
