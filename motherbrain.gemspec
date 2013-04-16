# -*- encoding: utf-8 -*-
require File.expand_path('../lib/mb/version', __FILE__)

Gem::Specification.new do |s|
  s.authors       = [
    "Jamie Winsor",
    "Jesse Howarth",
    "Justin Campbell",
    "Michael Ivey"
  ]
  s.email         = [
    "reset@riotgames.com",
    "jhowarth@riotgames.com",
    "justin.campbell@riotgames.com",
    "michael.ivey@riotgames.com"
  ]
  s.description   = %q{An orchestrator for Chef}
  s.summary       = s.description
  s.homepage      = "https://github.com/RiotGames/motherbrain"
  s.license       = "Apache 2.0"

  s.files         = `git ls-files`.split($\)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(spec|features)/})
  s.name          = "motherbrain"
  s.require_paths = ["lib"]
  s.version       = MotherBrain::VERSION
  s.required_ruby_version = ">= 1.9.3"

  s.add_runtime_dependency 'celluloid', '~> 0.13.0'
  s.add_runtime_dependency 'dcell', '~> 0.13.0'
  s.add_runtime_dependency 'reel', '>= 0.3.0'
  s.add_runtime_dependency 'grape', '>= 0.3.2'
  s.add_runtime_dependency 'net-ssh'
  s.add_runtime_dependency 'net-sftp'
  s.add_runtime_dependency 'solve', '>= 0.4.1'
  s.add_runtime_dependency 'ridley', '>= 0.10.0.rc3'
  s.add_runtime_dependency 'chozo', '~> 0.6.0'
  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'thor', '~> 0.18.0'
  s.add_runtime_dependency 'faraday'
  s.add_runtime_dependency 'ef-rest', '>= 0.1.0'
  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'multi_json'
  s.add_runtime_dependency 'fog', '~> 1.10.0'
end
