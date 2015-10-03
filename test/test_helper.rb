require 'vcr'
require 'webmock'
require 'simplecov'
require 'minitest/spec'
require 'minitest/autorun'
require_relative '../lib/elasticsearch/drain'
require 'elasticsearch/extensions/test/cluster'

gem 'minitest'
SimpleCov.start

VCR.configure do |c|
  c.cassette_library_dir = 'test/cassettes'
  c.hook_into :webmock
end
