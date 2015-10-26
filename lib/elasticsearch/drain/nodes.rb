module Elasticsearch
  class Drain
    class Nodes < Drain
      # @!attribute [r]
      # The Elasticsearch node stats json object
      attr_reader :stats

      # @!attribute [r]
      # The Elasticsearch node info json object
      attr_reader :info

      def initialize(*args)
        @args = *args
        super(*args)
        load
      end

      def load
        @info = client.nodes.info metric: '_all'
        @stats = client.nodes.stats metric: '_all'
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
            @args
          )
        end
      end

      def nodes_in_asg(reload: false, instances:)
        nodes(reload).find_all { |n| instances.include? n }
      end
    end
  end
end

require 'elasticsearch'
