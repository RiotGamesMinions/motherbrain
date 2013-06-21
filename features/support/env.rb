ENV['RUBY_ENV'] ||= 'test'
ENV['MOTHERBRAIN_PATH'] ||= File.join(File.expand_path("../../", File.dirname(__FILE__)), "spec/tmp/.mb")
ENV['BERKSHELF_PATH'] ||= File.join(File.expand_path("../../", File.dirname(__FILE__)), "spec/tmp/.berkshelf")

require 'rubygems'
require 'bundler'
require 'motherbrain'

def setup_env
  require 'rspec'
  require 'aruba/cucumber'
  require 'aruba/in_process'
  require 'aruba/spawn_process'

  Dir[File.join(File.expand_path("../../../spec/support/**/*.rb", __FILE__))].each { |f| require f }

  RSpec.configure do |config|
    config.include MotherBrain::SpecHelpers

    config.before(:each) do
      clean_tmp_path
    end
  end

  Aruba::InProcess.main_class = MB::Cli::Runner
  Aruba.process               = Aruba::InProcess

  World(Aruba::Api)
  World(MotherBrain::SpecHelpers)

  Before do
    @config = generate_valid_config
  end

  Before('@in-process') do
    Aruba.process = Aruba::InProcess
  end

  Before('@spawn') do
    Aruba.process = Aruba::SpawnProcess
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
