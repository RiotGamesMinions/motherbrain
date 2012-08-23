# -*- encoding: utf-8 -*-
require File.expand_path('../lib/mb/version', __FILE__)

Gem::Specification.new do |s|
  s.authors       = ["Jamie Winsor"]
  s.email         = ["jamie@vialstudios.com"]
  s.description   = %q{TODO: Write a gem description}
  s.summary       = %q{TODO: Write a gem summary}
  s.homepage      = ""

  s.files         = `git ls-files`.split($\)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(spec|features)/})
  s.name          = "motherbrain"
  s.require_paths = ["lib"]
  s.version       = MotherBrain::VERSION
  s.required_ruby_version = ">= 1.9.1"

  s.add_runtime_dependency 'ridley'
  s.add_runtime_dependency 'chozo'
  s.add_runtime_dependency 'nexus_cli', '~> 0.3.0'

  s.add_development_dependency 'cucumber'
  s.add_development_dependency 'aruba'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'fuubar'
  s.add_development_dependency 'spork'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'guard-cucumber'
  s.add_development_dependency 'guard-spork'
  s.add_development_dependency 'guard-yard'
  s.add_development_dependency 'coolline'
  s.add_development_dependency 'redcarpet'
  s.add_development_dependency 'json_spec'
  s.add_development_dependency 'webmock'
end
