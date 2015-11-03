require 'thor'
module Elasticsearch
  class Drain
    class CLI < ::Thor
      package_name :elasticsearch

      desc 'asg', 'Drain all documents from all nodes in an EC2 AutoScaling Group'
      option :host, default: 'localhost:9200'
      option :asg, required: true
      option :region, required: true
      def asg
        drainer = Elasticsearch::Drain.new(options[:host],
                                           options[:asg],
                                           options[:region])
        drainer.drain
      end
    end
  end
end
