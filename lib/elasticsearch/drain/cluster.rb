##
# Representation of the cluster
#
module Elasticsearch
  class Drain
    class Cluster < Drain
      # @attribute [r]
      # Elasticsearch Cluster Object
      attr_reader :cluster

      def initialize(_)
        super
        @cluster = client.cluster
      end

      def healthy?
        health = cluster.health(
          wait_for_status: 'green',
          timeout: 60
        )
        health['status'] == 'green'
      end

      def relocating_shards?
        return true unless healthy?
        health = cluster.health(
          wait_for_status: 'green',
          wait_for_relocating_shards: 3,
          timeout: 60
        )
        health['relocating_shards'] <= 3
      end
    end
  end
end
