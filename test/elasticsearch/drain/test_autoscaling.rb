require 'test_helper'
require 'pp'

class TestAutoScaling < Minitest::Test
  def setup
    VCR.insert_cassette 'autoscaling', record: :new_episodes
    @asg = ::Elasticsearch::Drain::AutoScaling.new(
      'esuilogs-razor-d0prod-r01-v000',
      'us-east-1'
    )
  end

  def teardown
    VCR.eject_cassette
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
    assert_match /i-[a-z0-9]{8}/, @asg.find_instances_in_asg.first
  end

  def test_instances_is_array
    assert_respond_to @asg.instances, :each
  end

  def test_instances_is_private_ipaddresses
    ip = @asg.instances.first
    assert private_ipaddress?(ip)
  end

  # TODO: Figure out how to recode this...
  def test_describe_asg_has_desired_capacity
    disable_vcr do
      asg = @asg.describe_autoscaling_group
      assert_respond_to asg, :desired_capacity
    end
  end

  # TODO: Figure out how to recode this...
  def test_describe_asg_desired_capacity_equals
    disable_vcr do
      asg = @asg.describe_autoscaling_group
      assert_equal 16, asg.desired_capacity
    end
  end

  # TODO: Figure out how to recode this...
  def test_describe_asg_has_min_size
    disable_vcr do
      asg = @asg.describe_autoscaling_group
      assert_respond_to asg, :min_size
    end
  end

  # TODO: Figure out how to recode this...
  def test_describe_asg_has_min_size_equals
    disable_vcr do
      asg = @asg.describe_autoscaling_group
      assert_equal 16, asg.min_size
    end
  end
end
