ENV['RUBY_ENV'] ||= 'test'
ENV['MOTHERBRAIN_PATH'] ||= File.join(File.expand_path("../../", File.dirname(__FILE__)), "spec/tmp/.mb")
ENV['BERKSHELF_PATH'] ||= File.join(File.expand_path("../../", File.dirname(__FILE__)), "spec/tmp/.berkshelf")
ENV['CHEF_API_URL'] = 'http://localhost:28891'

require 'rubygems'
require 'bundler'
require 'motherbrain'

def setup_env
  require 'rspec'
  require 'aruba/cucumber'
  require 'aruba/in_process'
  require 'aruba/spawn_process'
  require 'chef_zero/server'

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
  World(MotherBrain::RSpec::ChefServer)

  WebMock.disable_net_connect!(allow_localhost: true, net_http_connect_on_start: true)
  MB::RSpec::ChefServer.start

  at_exit { MB::RSpec::ChefServer.stop }

  Before do
    @aruba_timeout_seconds = 10
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
