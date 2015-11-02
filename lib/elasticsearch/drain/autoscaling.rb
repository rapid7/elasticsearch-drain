module Elasticsearch
  class Drain
    class AutoScaling

      # @attribute [r]
      # EC2 AutoScaling Group name
      attr_reader :asg

      # @attribute [r]
      # EC2 Client
      attr_reader :ec2_client

      def initialize(asg, region)
        @asg = asg
        @asg_client = Aws::AutoScaling::Client.new(region: region)
        @ec2_client = Aws::EC2::Client.new(region: region)
        @instances = nil
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
        @instances = instances
      end

      def describe_instances
        instances = []
        find_instances_in_asg if @instances.nil?
        return [] if @instances.empty?
        @ec2_client.describe_instances(instance_ids: @instances).each do |page|
          instances << page.reservations.map(&:instances)
        end
        instances.flatten!
        @instances = instances
      end

      def find_private_ips
        instances = describe_instances
        return [] if instances.nil?
        instances.map!(&:private_ip_address)
        instances.flatten!
        instances
      end

      def instances
        find_instances_in_asg
        find_private_ips
      end

      def instance(ipaddress)
        describe_instances if @instances.nil?
        @instances.find { |i| i.private_ip_address == ipaddress }
      end

      # Sets the MinSize of an AutoScalingGroup
      #
      # @option [FixNum] count (0) The new MinSize of the AutoScalingGroup
      # @return [Struct] Empty response from the sdk
      def min_size(count = 0)
        @asg_client.update_auto_scaling_group(
          auto_scaling_group_name: asg,
          min_size: count
        )
      end

      def detach_instance(instance_id)
        resp = @asg_client.detach_instances(
          instance_ids: [instance_id],
          auto_scaling_group_name: asg,
          should_decrement_desired_capacity: true
        )
        resp.activities.first.status_code == 'Successful'
      end
    end
  end
end
require 'aws-sdk'
