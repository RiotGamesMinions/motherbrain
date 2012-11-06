source :rubygems

gemspec

platforms :ruby do
  gem 'yajl-ruby'
  gem 'mysql2'
end

platforms :jruby do
  gem 'jmx4r'
  gem 'json-jruby'
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

  gem 'spork'
  gem 'rspec'
end
