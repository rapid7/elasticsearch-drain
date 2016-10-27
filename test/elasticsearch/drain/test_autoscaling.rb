require 'test_helper'
require 'pp'

class TestAutoScaling < Minitest::Test
  def setup
    Aws.config[:stub_responses] = true
    @asg = ::Elasticsearch::Drain::AutoScaling.new('my-asg', 'us-east-1')
    stub_describe_auto_scaling_groups(@asg.asg_client, ['i-abcd1234', 'i-1234abcd'], 'my-asg')
    stub_describe_auto_scaling_instances(@asg.asg_client, ['i-abcd1234', 'i-1234abcd'], 'my-asg')
    stub_ec2_describe_instances(@asg.ec2_client, 'i-abcd1245' => '192.168.0.3', 'i-1234abcd' => '192.168.0.4')
  end

  def stub_describe_auto_scaling_groups(asg_client, instances, asg_name)
    raise ArgumentError, 'instances must be an array' unless instances.respond_to?(:each)

    launch_config_name = "#{asg_name}-#{SecureRandom.hex[0..10].upcase}"
    new_instances = []
    instances.each do |instance|
      instance_hash = instance_hash(instance, availability_zones.sample)
      instance_hash[:launch_configuration_name] = launch_config_name
      new_instances << instance_hash
    end

    asg_client.stub_responses(:describe_auto_scaling_groups,
                              auto_scaling_groups: [{
                                auto_scaling_group_name: asg_name,
                                min_size: instances.length,
                                max_size: instances.length,
                                desired_capacity: instances.length,
                                default_cooldown: 300,
                                availability_zones: ['us-east-1b', 'us-east-1a', 'us-east-1e', 'us-east-1d'],
                                health_check_type: 'EC2',
                                created_time: Time.now,
                                instances: new_instances
                              }])
  end

  def stub_describe_auto_scaling_instances(asg_client, instances, asg_name)
    raise ArgumentError, 'instances must be an array' unless instances.respond_to?(:each)

    launch_config_name = "#{asg_name}-#{SecureRandom.hex[0..10].upcase}"
    new_instances = []
    instances.each do |instance|
      instance_hash = instance_hash(instance, availability_zones.sample)
      instance_hash[:launch_configuration_name] = launch_config_name
      instance_hash[:auto_scaling_group_name] = asg_name
      new_instances << instance_hash
    end

    asg_client.stub_responses(:describe_auto_scaling_instances, auto_scaling_instances: new_instances)
  end

  def stub_ec2_describe_instances(ec2_client, instances)
    raise ArgumentError, 'instances must be a hash {INSTANCE_ID => IPADDRESS}' unless instances.respond_to?(:each_pair)
    new_instances = []
    instances.each_pair do |instance, ipaddress|
      new_instances << {
        instance_id: instance,
        private_ip_address: ipaddress
      }
    end
    ec2_client.stub_responses(:describe_instances,
                              reservations: [instances: new_instances])
  end

  def availability_zones
    ['us-east-1b', 'us-east-1a', 'us-east-1e', 'us-east-1d']
  end

  def instance_hash(instance_id, az)
    {
      instance_id: instance_id,
      availability_zone: az,
      lifecycle_state: 'InService',
      health_status: 'HEALTY',
      protected_from_scale_in: false
    }
  end

  def test_asg
    assert_respond_to @asg, :asg
  end

  def test_find_instances_is_array
    assert_respond_to @asg.find_instances_in_asg, :each
  end

  def test_missing_instance
    assert_raises(::Elasticsearch::Drain::Errors::NodeNotFound) do
      @asg.instance('1.1.1.1')
    end
  end

  def test_find_instances_matches_instance_pattern
    assert_match(/i-[a-z0-9]{8}/, @asg.find_instances_in_asg.first)
  end

  def test_instances_array_not_empty
    assert_respond_to @asg.instances, :each
    refute_empty @asg.instances
  end

  def test_instances_not_nil
    refute_nil @asg.instances.first
  end

  def test_instances_is_private_ipaddresses
    ip = @asg.instances.first
    assert private_ipaddress?(ip)
  end

  def test_describe_asg_has_desired_capacity
    asg = @asg.describe_autoscaling_group
    assert_respond_to asg, :desired_capacity
  end

  def test_describe_asg_desired_capacity_equals
    asg = @asg.describe_autoscaling_group
    assert_equal 2, asg.desired_capacity
  end

  def test_describe_asg_has_min_size
    asg = @asg.describe_autoscaling_group
    assert_respond_to asg, :min_size
  end

  def test_describe_asg_has_min_size_equals
    asg = @asg.describe_autoscaling_group
    assert_equal 2, asg.min_size
  end
end
