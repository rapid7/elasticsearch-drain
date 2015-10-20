module Elasticsearch
  class Drain
    class Nodes < Drain
      # @!attribute [r]
      # The Elasticsearch node stats json object
      attr_reader :stats

      # @!attribute [r]
      # The Elasticsearch node info json object
      attr_reader :info

      def initialize(_)
        super(_)
        @info = client.nodes.info metric: '_all'
        @stats = client.nodes.stats metric: '_all'
      end

      # Get list of nodes in the cluster
      #
      # @return [Array<OpenStruct>] Array of node objects
      def nodes # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        @info['nodes'].map do |node|
          stats = node[1]
          OpenStruct.new(
            id: node[0],
            version: stats['version'],
            hostname: stats['host'],
            name: stats['name'],
            ipaddress: stats['ip'],
            transport_address: address(stats['transport_address']),
            http_address: address(stats['http_address']),
            bytes_stored: bytes_stored(node[0])
          )
        end
      end

      # Extract ip:port from string passed in
      #
      # @param [String] str The address object to parse for the ip:port
      # @return [String] ip:port pair from the data passed in
      def address(str)
        str.match(/.+\[\/(.+)\]/)[1]
      end

      # Get size in bytes used for indices for a node
      #
      # @param [String] id describe id
      # @return [Integer] size in bytes used to store indicies on node
      def bytes_stored(id)
        node = stats['nodes'].find { |n| n[0] == id }
        node = node[1]
        node['indices']['store']['size_in_bytes']
      end
    end
  end
end

require 'elasticsearch'
