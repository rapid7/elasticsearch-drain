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

  def test_describe_asg_has_desired_capacity
    VCR.eject_cassette
    WebMock.allow_net_connect!
    VCR.turned_off do
      asg = @asg.describe_autoscaling_group
      assert_respond_to asg, :desired_capacity
    end
    WebMock.disable_net_connect!
  end
end
