require 'test_helper'
require 'pp'

class TestNodes < Minitest::Test
  def setup
    VCR.insert_cassette 'nodes', record: :new_episodes
    @drain = ::Elasticsearch::Drain.new(
      'localhost:9250',
      'esuilogs-razor-d0prod-r01-v000',
      'us-west-2'
    )
    @nodes = ::Elasticsearch::Drain::Nodes.new(@drain.client, @drain.asg)
  end

  def teardown
    VCR.eject_cassette
  end

  def test_has_nodes
    assert_respond_to @nodes, :client
  end

  def test_nodes_is_array
    assert_respond_to @nodes.nodes, :each
  end

  def test_has_info
    assert_respond_to @nodes, :info
  end

  def test_info_has_value
    assert_respond_to @nodes.info, :each
  end

  def test_has_stats
    assert_respond_to @nodes, :stats
  end

  def test_stats_has_value
    assert_respond_to @nodes.stats, :each
  end
end
