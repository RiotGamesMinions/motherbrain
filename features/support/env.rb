ENV['RUBY_ENV'] ||= 'test'
ENV['MOTHERBRAIN_PATH'] ||= File.join(File.expand_path("../../", File.dirname(__FILE__)), "spec/tmp/.mb")
ENV['BERKSHELF_PATH'] ||= File.join(File.expand_path("../../", File.dirname(__FILE__)), "spec/tmp/.berkshelf")

require 'rubygems'
require 'bundler'
require 'motherbrain'

def setup_env
  require 'rspec'
  require 'aruba/cucumber'
  require 'chef_zero/server'
  Dir[File.join(File.expand_path("../../../spec/support/**/*.rb", __FILE__))].each { |f| require f }

  RSpec.configure do |config|
    config.include MotherBrain::SpecHelpers

    config.before(:each) do
      clean_tmp_path
    end
  end

  World(Aruba::Api)
  World(MotherBrain::SpecHelpers)

  ENV['CHEF_API_URL'] = 'http://localhost:28889'

  MotherBrain::SpecHelpers.chef_zero.start_background

  at_exit do
    MotherBrain::SpecHelpers.chef_zero.stop
  end

  Before do
    MotherBrain::SpecHelpers.chef_zero.clear_data

    @aruba_timeout_seconds = 10
    @config = generate_valid_config
  end
end

if jruby?
  setup_env
else
  require 'spork'

  Spork.prefork do
    setup_env
  end

  Spork.each_run do
    require 'motherbrain'

    World(MB::Mixin::CodedExit)
  end
end

