# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'elasticsearch/drain/version'

Gem::Specification.new do |spec|
  spec.name          = 'elasticsearch-drain'
  spec.version       = Elasticsearch::Drain::VERSION
  spec.authors       = ['Andrew Thompson']
  spec.email         = ['Andrew_Thompson@rapid7.com']
  spec.summary       = %q{Elasticsearch node replacement utility that tries to keep the cluster healthy}
  spec.description   = %q{The purpose of this utility is to drain documents from Elasticsearch nodes in an AutoScaling Group}
  spec.homepage      = 'https://github.com/rapid7/elasticsearch-drain'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.1'
  spec.add_development_dependency 'rake', '~> 10.0'

  spec.add_dependency 'elasticsearch', '~> 1.0'
  spec.add_dependency 'aws-sdk', '~> 3'
  spec.add_dependency 'thor', '~> 0.19'
end
