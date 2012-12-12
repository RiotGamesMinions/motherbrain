source :rubygems

gemspec

gem 'reel', git: 'git://github.com/celluloid/reel.git'
gem 'ridley', git: 'git://github.com/reset/ridley.git'
gem 'chozo', git: 'git://github.com/reset/chozo.git'
gem 'ef-rest', git: 'git@github.com:RiotGames/ef-rest.git'

platforms :ruby do
  gem 'yajl-ruby'
  gem 'mysql2'
  gem 'yajl-ruby'
end

platforms :jruby do
  gem 'jmx4r'
  gem 'json-jruby'
  gem 'jdbc-mysql'
end

group :development do
  gem 'cucumber'
  gem 'aruba'
  gem 'rspec'
  gem 'fuubar'
  gem 'yard'
  gem 'redcarpet'
  gem 'coolline'
  gem 'webmock'
  gem 'json_spec'

  gem 'guard', '>= 1.5.0'
  gem 'guard-rspec', '>= 2.0.0'
  gem 'guard-cucumber'
  gem 'guard-yard'
  gem 'guard-spork', platforms: :ruby

  require 'rbconfig'

  if RbConfig::CONFIG['target_os'] =~ /darwin/i
    gem 'growl', require: false
    gem 'rb-fsevent', require: false

    if `uname`.strip == 'Darwin' && `sw_vers -productVersion`.strip >= '10.8'
      gem 'terminal-notifier-guard', '~> 1.5.3', require: false
    end rescue Errno::ENOENT

  elsif RbConfig::CONFIG['target_os'] =~ /linux/i
    gem 'libnotify',  '~> 0.7.1', require: false
    gem 'rb-inotify', require: false

  elsif RbConfig::CONFIG['target_os'] =~ /mswin|mingw/i
    gem 'win32console', require: false
    gem 'rb-notifu', '>= 0.0.4', require: false
    gem 'wdm', require: false
  end
end

group :test do
  gem 'rake', '>= 0.9.2.2'
  gem 'rack-test'
  gem 'spork'
  gem 'rspec'
end
