require 'test_helper'

class TestDrain < Minitest::Test
  def setup
    @drain = ::Elasticsearch::Drain.new(hosts: 'localhost:9250')
  end

  def test_nodes_method
    assert_respond_to @drain, :nodes
  end

  def test_has_hosts_attribute
    assert_respond_to @drain, :hosts
  end

  def test_nodes_in_recovery
    skip("NYI")
    assert_respond_to @drain.recovery :each
  end
end
