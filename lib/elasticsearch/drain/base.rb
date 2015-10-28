module Elasticsearch
  class Drain
    class Base
      # @attribute [r]
      # The Elasticsearch client object
      attr_reader :client

      def initialize(client)
        @client = client
      end
    end
  end
end
