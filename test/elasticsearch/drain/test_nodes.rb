require 'test_helper'
require 'pp'

class TestNodes < Minitest::Test
  def setup
    @nodes = ::Elasticsearch::Drain::Nodes.new(hosts: 'localhost:9350')
    @cassette = 'nodes'
  end

  def test_has_client
    VCR.use_cassette(@cassette) do
      assert_respond_to @nodes, :client
    end
  end

  def test_have_2_nodes_in_array
    VCR.use_cassette(@cassette) do
      assert_respond_to @nodes.nodes, :each
    end
  end

  def test_bytes_stored_on_host_is_num
    skip("NYI")
    VCR.use_cassette(@cassette) do
      pp @drain.es_client
      #pp @drain.es_client.methods

      pp @drain.nodes
      pp @drain.nodes.methods
      assert_respond_to @drain.nodes.first.bytes, :+
    end
  end

  def test_nodes_in_recovery
    skip("NYI")
    assert_respond_to @drain.recovery :each
  end
end
