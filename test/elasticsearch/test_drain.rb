require 'test_helper'

class TestDrain < Minitest::Test
  def setup
    VCR.insert_cassette 'drain', record: :new_episodes
    @drain = ::Elasticsearch::Drain.new(
      'localhost:9250',
      'esuilogs-razor-d0prod-r01-v000',
      'us-west-2'
    )
  end

  def teardown
    VCR.eject_cassette
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

  def test_cluster_health_is_valid
    assert (@drain.cluster.healthy? || %w(red yellow green).include?(@drain.cluster.health['status']))
  end

  def test_es_cluster_hosts_match
    assert_equal 'localhost:9250', @drain.hosts
  end
end
