require 'vcr'
require 'ipaddr'
require 'webmock'
require 'simplecov'
require 'minitest/spec'
require 'minitest/autorun'
require 'elasticsearch/extensions/test/cluster'

gem 'minitest'
SimpleCov.start

require_relative '../lib/elasticsearch/drain'

VCR.configure do |c|
  c.cassette_library_dir = 'test/cassettes'
  c.hook_into :webmock
#  c.debug_logger = $stderr
#  c.default_cassette_options = { allow_playback_repeats: true }
end

def private_ipaddress?(ip)
  class_a = IPAddr.new('10.0.0.0/8')
  class_b = IPAddr.new('172.16.0.0/12')
  class_c = IPAddr.new('192.168.0.0/16')
  [class_a, class_b, class_c].any? { |i| i.include?(ip) }
end
