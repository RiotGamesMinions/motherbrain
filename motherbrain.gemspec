# -*- encoding: utf-8 -*-
require File.expand_path('../lib/mb/version', __FILE__)

Gem::Specification.new do |s|
  s.authors       = ["Jamie Winsor"]
  s.email         = ["jamie@vialstudios.com"]
  s.description   = %q{An orchestrator for Chef}
  s.summary       = s.description
  s.homepage      = "https://github.com/RiotGames/motherbrain"

  s.files         = `git ls-files`.split($\)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(spec|features)/})
  s.name          = "motherbrain"
  s.require_paths = ["lib"]
  s.version       = MotherBrain::VERSION
  s.required_ruby_version = ">= 1.9.1"

  s.add_runtime_dependency 'solve', '>= 0.3.1'
  s.add_runtime_dependency 'ridley', '>= 0.4.1'
  s.add_runtime_dependency 'chozo', '>= 0.2.2'
  s.add_runtime_dependency 'nexus_cli', '~> 0.3.0'
  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'rye'
  s.add_runtime_dependency 'thor', '>= 0.16.0'
end
