source "https://rubygems.org"
source "http://gems.riotgames.com"

gemspec

if File.exists?('Gemfile.local') then
  eval File.read('Gemfile.local'), nil, 'Gemfile.local'
end

platforms :ruby do
  gem 'mysql2'
  gem 'yajl-ruby'
end

platforms :jruby do
  gem 'jdbc-mysql'
  gem 'jmx4r'
  gem 'json-jruby'
end

group :development do
  gem 'aruba'
  gem 'coolline'
  gem 'cucumber'
  gem 'debugger', '>= 1.3.2', platforms: :ruby
  gem 'fuubar'
  gem 'json_spec'
  gem 'redcarpet', platforms: :ruby
  gem 'rspec'
  gem 'webmock'
  gem 'yard'
  gem 'geminabox'

  gem 'guard'
  gem 'guard-cucumber'
  gem 'guard-rspec'
  gem 'guard-spork', platforms: :ruby
  gem 'guard-yard'

  gem 'ronn', platforms: :ruby

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
    gem 'rb-notifu', '>= 0.0.4', require: false
    gem 'wdm', require: false
    gem 'win32console', require: false
  end
end

group :test do
  gem 'rack-test'
  gem 'rake', '>= 0.9.2.2'
  gem 'rspec'
  gem 'spork'
end
