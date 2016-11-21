module Elasticsearch
  class Drain
    class AutoScaling
      include Drain::Util

      # @attribute [r]
      # EC2 AutoScaling Group name
      attr_reader :asg

      # @attribute [r]
      # AWS region
      attr_reader :region

      def initialize(asg, region)
        @asg = asg
        @region = region
        @instances = nil
        @instance_ids = nil
      end

      def asg_client
        Aws::AutoScaling::Client.new(region: region)
      end

      def ec2_client
        Aws::EC2::Client.new(region: region)
      end

      def find_instances_in_asg
        instances = []
        asg_client.describe_auto_scaling_instances.each do |page|
          instances << page.auto_scaling_instances.map do |i|
            i.instance_id if i.auto_scaling_group_name == asg
          end
        end
        instances.flatten!
        instances.compact!
        @instance_ids = instances
      end

      # Get instances in an AutoScaling Group
      #
      # @return [Array<Aws::EC2::Types::Instance>] EC2 Instance objects
      def describe_instances
        instances = []
        find_instances_in_asg if @instance_ids.nil?
        return [] if @instance_ids.empty?
        ec2_client.describe_instances(instance_ids: @instance_ids).each do |page|
          instances << page.reservations.map(&:instances)
        end
        instances.flatten!
        @instances = instances
      end

      # Describe an AutoScaling Group
      #
      # @return [Struct] AutoScaling Group
      def describe_autoscaling_group
        groups = asg_client.describe_auto_scaling_groups(
          auto_scaling_group_names: [asg]
        )
        groups.auto_scaling_groups.first
      end

      def find_private_ips
        instances = describe_instances.clone
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
        instances = @instances.clone
        instance = instances.find { |i| i.private_ip_address == ipaddress }
        fail Errors::NodeNotFound if instance.nil?
        instance
      end

      # Sets the MinSize of an AutoScalingGroup
      #
      # @option [FixNum] count (0) The new MinSize of the AutoScalingGroup
      # @return [Struct] Empty response from the sdk
      def min_size=(count = 0)
        asg_client.update_auto_scaling_group(
          auto_scaling_group_name: asg,
          min_size: count
        )
        wait_until(count) do
          min_size
        end
      end

      # Gets the MinSize of an AutoScalingGroup
      #
      # @return [Integer] Value of MinSize of an AutoScalingGroup
      def min_size
        group = describe_autoscaling_group
        group.min_size
      end

      # Gets the DesiredCapacity of an AutoScalingGroup
      #
      # @return [Integer] Value of DesiredCapacity of an AutoScalingGroup
      def desired_capacity
        group = describe_autoscaling_group
        group.desired_capacity
      end

      def detach_instance(instance_id)
        current_desired_capacity = desired_capacity
        asg_client.detach_instances(
          instance_ids: [instance_id],
          auto_scaling_group_name: asg,
          should_decrement_desired_capacity: true
        )
        wait_until(current_desired_capacity - 1) do
          desired_capacity
        end
      end
    end
  end
end
require 'aws-sdk'
