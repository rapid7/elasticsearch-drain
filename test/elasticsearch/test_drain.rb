require 'test_helper'

class TestDrain < Minitest::Test
  def setup
    @drain = ::Elasticsearch::Drain.new(hosts: 'localhost:9350')
    @cassette = 'drain'
  end

  def test_nodes_method
    VCR.use_cassette(@cassette) do
      assert_respond_to @drain, :nodes
    end
  end

  def test_nodes_in_recovery
    skip("NYI")
    assert_respond_to @drain.recovery :each
  end
end
