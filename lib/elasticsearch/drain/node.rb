module Elasticsearch
  class Drain
    class Node < Base
      # @!attribute [r]
      # The Elasticsearch node stats json object
      attr_reader :stats

      # @!attribute [r]
      # The Elasticsearch node info json object
      attr_reader :info

      # @!attribute [rw]
      # The Elasticsearch node Instance ID
      attr_accessor :instance_id

      def initialize(stats, info, client, asg)
        super(client)
        @stats = stats
        @info = info
        @asg = asg
        @instance_id = nil
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
        info[1]['http_address'].split(':')[0]
      end

      # The Elasticsearch node Transport Address
      #
      # @return [String] Elasticsearch node Transport Address
      def transport_address
        info[1]['transport_address']
      end

      # The Elasticsearch node HTTP Address
      #
      # @return [String] Elasticsearch nodes HTTP Address
      def http_address
        info[1]['http_address']
      end

      # Get size in bytes used for indices for a node
      #
      # @return [Integer] size in bytes used to store indicies on node
      def bytes_stored
        stats[1]['indices']['store']['size_in_bytes']
      end

      def in_recovery?
        recovery = client.cat.recovery(format: 'json', v: true).first.values
        [hostname, name].any? { |a| recovery.include?(a) }
      end

      def terminate
        @asg.ec2_client.terminate_instances(
          dry_run: false,
          instance_ids: [instance_id], # required
        )
        # poll for ~5mins seconds
        @asg.ec2_client.wait_until(:instance_terminated,
                                   instance_ids: [instance_id]) do |w|
          w.max_attempts = 10
          w.delay = 30
        end
      end
    end
  end
end
