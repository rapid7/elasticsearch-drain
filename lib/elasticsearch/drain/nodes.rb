module Elasticsearch
  class Drain
    class Nodes < Base
      # @!attribute [r]
      # The Elasticsearch node stats json object
      attr_reader :stats

      # @!attribute [r]
      # The Elasticsearch node info json object
      attr_reader :info

      def initialize(client, asg)
        super(client)
        @asg = asg
        load
      end

      def load
        tries ||= 3
        @info = client.nodes.info metric: '_all'
        @stats = client.nodes.stats metric: '_all'
      rescue Faraday::TimeoutError
        retry unless (tries -= 1).zero?
      end

      # Get list of nodes in the cluster
      #
      # @return [Array<OpenStruct>] Array of node objects
      def nodes(reload: false)
        load if reload
        @info['nodes'].map do |node|
          Drain::Node.new(
            stats['nodes'].find { |n| n[0] == node[0] },
            node,
            client,
            @asg
          )
        end
      end

      def nodes_in_asg(reload: false, instances:)
        nodes(reload: false).find_all { |n| instances.include? n.ipaddress }
      end
    end
  end
end

require 'elasticsearch'
