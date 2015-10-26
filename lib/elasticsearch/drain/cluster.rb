##
# Representation of the cluster
#
module Elasticsearch
  class Drain
    class Cluster < Drain
      # @attribute [r]
      # Elasticsearch Cluster Object
      attr_reader :cluster

      def initialize(*args)
        super(*args)
        @cluster = client.cluster
      end

      def health(opts = {})
        default_opts = {
          wait_for_status: 'green',
          timeout: 60
        }
        opts = default_opts.merge(opts)
        cluster.health(opts)
      end

      def healthy?
        health['status'] == 'green'
      end

      def relocating_shards?
        return true unless healthy?
        health(wait_for_relocating_shards: 3)['relocating_shards'] >= 3
      end

      def drain_nodes(nodes, exclude_by = '_ip')
        cluster.put_settings(
          body: {
            transient: { "cluster.routing.allocation.exclude.#{exclude_by}" => nodes }
          }
        )
      end
    end
  end
end
