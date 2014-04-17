# -*- encoding: utf-8 -*-
require File.expand_path('../lib/mb/version', __FILE__)

Gem::Specification.new do |s|
  s.authors       = [
    "Jamie Winsor",
    "Jesse Howarth",
    "Justin Campbell",
    "Michael Ivey",
    "Cliff Dickerson",
    "Andrew Garson",
    "Kyle Allan",
    "Josiah Kiehl",
  ]
  s.email         = [
    "jamie@vialstudios.com",
    "jhowarth@riotgames.com",
    "justin@justincampbell.me",
    "michael.ivey@riotgames.com",
    "cdickerson@riotgames.com",
    "agarson@riotgames.com",
    "kallan@riotgames.com",
    "jkiehl@riotgames.com",
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

  s.add_dependency 'celluloid', '~> 0.15'
  # s.add_dependency 'dcell', '~> 0.14.0'
  s.add_dependency 'reel', '~> 0.4.0'
  s.add_dependency 'reel-rack'
  s.add_dependency 'http', '~> 0.5.0'
  s.add_dependency 'grape', '~> 0.6.0'
  s.add_dependency 'net-ssh'
  s.add_dependency 'net-sftp'
  s.add_dependency 'solve', '~> 1.1'
  s.add_dependency 'ridley-connectors', '~> 2.0'
  s.add_dependency 'thor', '~> 0.18.0'
  s.add_dependency 'faraday', '~> 0.9'
  s.add_dependency 'multi_json'
  s.add_dependency 'fog', '~> 1.10.0'
  s.add_dependency 'json', '>= 1.8.0'
  s.add_dependency 'buff-config', '~> 0.3'
  s.add_dependency 'buff-extensions', '~> 0.5'
  s.add_dependency 'buff-platform', '~> 0.1'
  s.add_dependency 'buff-ruby_engine', '~> 0.1'
  s.add_dependency 'grape-swagger', '~> 0.6.0'
  s.add_dependency 'berkshelf', '~> 3.0'
  s.add_dependency 'semverse', '~> 1.1'
end
