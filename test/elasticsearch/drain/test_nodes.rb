require 'test_helper'
require 'pp'

class TestNodes < Minitest::Test
  def setup
    VCR.insert_cassette 'nodes'
    @nodes = ::Elasticsearch::Drain::Nodes.new('localhost:9250')
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

  def test_asg
    assert_respond_to @nodes, :asg
  end

  def test_region
    assert_respond_to @nodes, :region
  end
end
