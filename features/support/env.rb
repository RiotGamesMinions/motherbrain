require 'rubygems'
require 'bundler'

require 'rspec'
require 'aruba/cucumber'

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
  set_mb_config_path
  set_plugin_path
end

require 'motherbrain'
