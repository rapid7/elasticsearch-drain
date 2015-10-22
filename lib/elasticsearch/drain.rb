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
    # EC2 AutoScaling Client
    attr_reader :asg

    # @attribute [r]
    # EC2 Region
    attr_reader :region

    # Sets up the Elasticsearch client
    #
    # @option [String] :hosts ('localhost:9200') The Elasticsearch hosts to connect to
    # @return [Elasticsearch::Transport::Client] Elasticsearch transport client
    def initialize(hosts: 'localhost:9200', asg:, region:)
      @hosts = hosts
      @asg = AutoScaling.new(asg, region)
      @region = region
      @client = ::Elasticsearch::Client.new(
        hosts: hosts,
        retry_on_failure: true,
        log: true,
        logger: Logger.new('es_client.log', 10, 1024000)
      )
    end

    # Convience method to access {Elasticsearch::Drain::Nodes#nodes}
    #
    # @return [Array<OpenStruct>] Array of node objects
    def nodes
      Nodes.new.nodes
    end
  end
end

require_relative 'drain/autoscaling'
require_relative 'drain/version'
require_relative 'drain/nodes'

