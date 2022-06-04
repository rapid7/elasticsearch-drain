require 'vcr'
require 'ipaddr'
require 'webmock'
require 'minitest/spec'
require 'minitest/autorun'
require 'elasticsearch/extensions/test/cluster'

gem 'minitest'

if ENV['COVERAGE'] || ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

require_relative '../lib/elasticsearch/drain'

VCR.configure do |c|
  c.cassette_library_dir = 'test/cassettes'
  c.hook_into :webmock
  # c.debug_logger = $stderr
  # c.default_cassette_options = { allow_playback_repeats: true }
end

def private_ipaddress?(ip)
  class_a = IPAddr.new('10.0.0.0/8')
  class_b = IPAddr.new('172.16.0.0/12')
  class_c = IPAddr.new('192.168.0.0/16')
  [class_a, class_b, class_c].any? { |i| i.include?(ip) }
end

def disable_vcr(&block)
  return skip unless ENV['ALLOW_DISABLED_VCR'] == 'true'
  puts 'WARNING: Running with VCR disabled!'
  VCR.eject_cassette
  WebMock.allow_net_connect!
  VCR.turned_off do
    block.call
  end
  WebMock.disable_net_connect!
end
