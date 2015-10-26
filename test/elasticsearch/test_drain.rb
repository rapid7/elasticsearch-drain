require 'test_helper'

class TestDrain < Minitest::Test
  def setup
    @drain = ::Elasticsearch::Drain.new(
      'localhost:9250',
      'esuilogs-razor-d0prod-r01-v000',
      'us-west-2'
    )
  end

  def test_nodes_method
    assert_respond_to @drain, :nodes
  end

  def test_has_hosts_attribute
    assert_respond_to @drain, :hosts
  end

  def test_has_asg
    assert_equal 'esuilogs-razor-d0prod-r01-v000', @drain.asg.asg
  end

  def test_has_region
    assert_equal 'us-west-2', @drain.region
  end

  def test_has_cluster
    assert_respond_to @drain, :cluster
  end
end
