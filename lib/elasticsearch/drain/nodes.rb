module Elasticsearch
  class Drain
    class Nodes < Drain

      # Get list of nodes in the cluster
      #
      # @return [Array<Elasticsearch::Drain::Node>] Array of node objects
      def nodes
        ids = client.nodes.info['nodes'].keys
        ids.map! { |id| Drain::Node.new(id: id, hosts: hosts) }
      end
    end
  end
end

require 'elasticsearch'
