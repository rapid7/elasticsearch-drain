module Elasticsearch
  class Drain
    class AutoScaling

      # @attribute [r]
      # EC2 AutoScaling Group name
      attr_reader :asg

      def initialize(asg, region)
        @asg = asg
        @asg_client = Aws::AutoScaling::Client.new(region: region)
        @ec2_client = Aws::EC2::Client.new(region: region)
      end

      def find_instances_in_asg
        instances = []
        @asg_client.describe_auto_scaling_instances.each do |page|
          instances << page.auto_scaling_instances.map do |i|
            i.instance_id if i.auto_scaling_group_name == asg
          end
        end
        instances.flatten!
        instances.compact!
        # p instances
        @instances = instances
      end

      def find_private_ips
        instances = []
        fail 'Must have @instances' unless @instances
        @ec2_client.describe_instances(instance_ids: @instances).each do |page|
          instances << page.reservations.map(&:instances)
        end
        instances.flatten!
        instances.map!(&:private_ip_address)
        instances.flatten!
        instances
      end

      def instances
        find_instances_in_asg
        find_private_ips
      end

      # Sets the MinSize of an AutoScalingGroup
      #
      # @option [FixNum] count (0) The new MinSize of the AutoScalingGroup
      # @return [Struct] Empty response from the sdk
      def min_count(count = 0)
        @asg_client.update_auto_scaling_group(
          auto_scaling_group_name: asg,
          min_size: count
        )
      end
    end
  end
end
require 'aws-sdk'
