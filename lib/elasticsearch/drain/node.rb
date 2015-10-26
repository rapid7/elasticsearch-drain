module Elasticsearch
  class Drain
    class Node < Drain
      # @!attribute [r]
      # The Elasticsearch node stats json object
      attr_reader :stats

      # @!attribute [r]
      # The Elasticsearch node info json object
      attr_reader :info

      def initialize(stats, info, *args)
        super(*args)
        @stats = stats
        @info = info
      end

      # The Elasticsearch node id
      #
      # @return [String] Elasticsearch node id
      def id
        info[0]
      end

      # The Elasticsearch node version
      #
      # @return [String] Elasticsearch node version
      def version
        info[1]['version']
      end

      # The Elasticsearch node hostname
      #
      # @return [String] Elasticsearch node hostname
      def hostname
        info[1]['host']
      end

      # The Elasticsearch node name
      #
      # @return [String] Elasticsearch node name
      def name
        info[1]['name']
      end

      # The Elasticsearch node ipaddress
      #
      # @return [String] Elasticsearch node ipaddress
      def ipaddress
        info[1]['ip']
      end

      # The Elasticsearch node Transport Address
      #
      # @return [String] Elasticsearch node Transport Address
      def transport_address
        address(info[1]['transport_address'])
      end

      # The Elasticsearch node HTTP Address
      #
      # @return [String] Elasticsearch nodes HTTP Address
      def http_address
        address(info[1]['http_address'])
      end

      # Get size in bytes used for indices for a node
      #
      # @return [Integer] size in bytes used to store indicies on node
      def bytes_stored
        stats[1]['indices']['store']['size_in_bytes']
      end

      # Extract ip:port from string passed in
      #
      # @param [String] str The address object to parse for the ip:port
      # @return [String] ip:port pair from the data passed in
      def address(str)
        str.match(/.+\[\/(.+)\]/)[1]
      end

      def nodes_in_asg(reload: false, instances:)
        nodes(reload).find_all { |n| instances.include? n }
      end

      def in_recovery?
        recovery = client.cat.recovery(format: 'json').first.values
        recovery.include?(node)
      end
    end
  end
end
