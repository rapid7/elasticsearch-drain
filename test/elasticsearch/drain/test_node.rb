require 'test_helper'
require 'pp'

class TestNode < Minitest::Test
  def setup
    VCR.insert_cassette 'node', record: :new_episodes
    @drain = ::Elasticsearch::Drain.new(
      'localhost:9250',
      'esuilogs-razor-d0prod-r01-v000',
      'us-west-2'
    )
    @node = ::Elasticsearch::Drain::Nodes.new(@drain.client).nodes.first
  end

  def teardown
    VCR.eject_cassette
  end

  def test_version
    assert_instance_of String, @node.version
  end

  def test_hostname
    assert_instance_of String, @node.hostname
  end

  def test_name
    assert_instance_of String, @node.name
  end

  def test_id
    assert_instance_of String, @node.id
  end

  def test_ipaddress
    assert_respond_to IPAddr.new(@node.ipaddress).to_i, :+
  end

  def test_transport_address
    ipaddress, port = @node.transport_address.split(':')
    assert_respond_to IPAddr.new(ipaddress).to_i, :+
    assert_respond_to port.to_i, :+
  end

  def test_http_address
    ipaddress, port = @node.http_address.split(':')
    assert_respond_to IPAddr.new(ipaddress).to_i, :+
    assert_respond_to port.to_i, :+
  end

  def test_bytes_stored_on_host
    assert_respond_to @node.bytes_stored, :+
  end

  def test_in_recovery
    assert @node.in_recovery?
  end
end
