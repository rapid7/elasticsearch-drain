require 'test_helper'
require 'pp'

class TestCluster < Minitest::Test
  def setup
    VCR.insert_cassette 'cluster', record: :new_episodes
    @drain = ::Elasticsearch::Drain.new(
      'localhost:9250',
      'esuilogs-razor-d0prod-r01-v000',
      'us-west-2'
    )
    @cluster = ::Elasticsearch::Drain::Cluster.new(@drain.client)
  end

  def teardown
    VCR.eject_cassette
  end

  def test_cluster_health_is_green
    assert @cluster.healthy?
  end

  def test_cluster_relocating_shards
    refute @cluster.relocating_shards?
  end
end
