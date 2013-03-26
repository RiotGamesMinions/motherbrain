ENV['RUBY_ENV'] ||= 'test'
ENV['MOTHERBRAIN_PATH'] ||= File.join(File.expand_path("../../", File.dirname(__FILE__)), "spec/.mb")
ENV['BERKSHELF_PATH'] ||= File.join(File.expand_path("../../", File.dirname(__FILE__)), "spec/tmp/.berkshelf")

require 'rubygems'
require 'bundler'
require 'motherbrain'

def setup_env
  require 'rspec'
  require 'aruba/cucumber'
  require 'cucumber/rspec/doubles'

  Dir[File.join(File.expand_path("../../../spec/support/**/*.rb", __FILE__))].each { |f| require f }

  RSpec.configure do |config|
    config.include MotherBrain::SpecHelpers

    config.before(:each) do
      clean_tmp_path
    end
  end

  World(Aruba::Api)
  World(MotherBrain::SpecHelpers)

  Before do
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
  end
end

