require 'test_helper'
require 'pp'

class TestCluster < Minitest::Test
  def setup
    VCR.insert_cassette 'cluster'
    @cluster = ::Elasticsearch::Drain::Cluster.new(
      hosts: 'localhost:9250',
      region: 'us-west-2',
      asg: 'esuilogs-razor-d0prod-r01-v000'
    )
  end

  def teardown
    VCR.eject_cassette
  end

  def test_cluster_health_is_green
    assert @cluster.healthy?
  end

  def test_cluster_relocating_shards
    assert @cluster.relocating_shards?
  end
end
