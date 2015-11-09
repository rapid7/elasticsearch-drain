require 'elasticsearch/extensions/test/cluster/tasks'
require 'elasticsearch/extensions/test/cluster'
require 'bundler/gem_tasks'
require 'rubocop/rake_task'
require 'rake/testtask'
require 'net/https'
require 'fileutils'
require 'zip'

RuboCop::RakeTask.new

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = 'test/**/test_*.rb'
end

def elasticsearch_command
  path = "tmp/elasticsearch-#{ENV['ES_VERSION']}/bin/elasticsearch"
  path = ::File.expand_path(path, __dir__)
  "bash #{path}"
end

ENV['TEST_CLUSTER_NODES'] = '1'
ENV['TEST_CLUSTER_COMMAND'] = elasticsearch_command
ENV['ES_VERSION'] ||= '1.7.2'

namespace :elasticsearch do
  task :clean do
    next if File.exist? 'tmp/es.lock'
    FileUtils.rm_rf 'tmp'
  end

  directory 'tmp'

  task :install_lock do
    FileUtils.touch 'tmp/es.lock'
  end

  # based on http://snippets.dzone.com/posts/show/2469
  # http://farm1.static.flickr.com/92/218926700_ecedc5fef7_o.jpg
  desc 'Download/extract Elasticsearch archive'
  task download: [:tmp] do
    next if File.exist? 'tmp/es.lock'
    Net::HTTP.start('download.elastic.co') do |http|
      resp = http.get("/elasticsearch/elasticsearch/elasticsearch-#{ENV['ES_VERSION']}.zip")
      open('tmp/es.zip', 'w') { |file| file.write(resp.body) }
    end
  end

  task :extract do
    next if File.exist? 'tmp/es.lock'
    Zip::File.open('tmp/es.zip') do |zip_file|
      # Handle entries one by one
      zip_file.each do |entry|
        # Extract to file/directory/symlink
        puts "Extracting #{entry.name}"
        entry.extract(::File.join('tmp', entry.name))
      end
    end
  end

  desc 'Install a test Elasticsearch Cluster in project directory'
  task install: [:clean, :download, :extract, :install_lock]
end

desc 'Start/Stop Elasticsearch Cluster to refresh test fixtures'
task refresh_fixtures: ['elasticsearch:install',
                        'elasticsearch:start',
                        'test',
                        'elasticsearch:stop']

desc 'Run unit and style tests'
task default: [:test, :rubocop]
