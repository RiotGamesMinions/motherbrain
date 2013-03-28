ENV['RUBY_ENV'] ||= 'test'
ENV['MOTHERBRAIN_PATH'] ||= File.join(File.expand_path(File.dirname(__FILE__)), ".mb")
ENV['BERKSHELF_PATH'] ||= File.join(File.expand_path(File.dirname(__FILE__)), "tmp/.berkshelf")

require 'rubygems'
require 'bundler'
require 'rspec'
require 'json_spec'
require 'webmock/rspec'
require 'rack/test'
require 'motherbrain'

def setup_rspec
  Dir[File.join(File.expand_path("../../spec/support/**/*.rb", __FILE__))].each { |f| require f }

  RSpec.configure do |config|
    config.include JsonSpec::Helpers
    config.include MotherBrain::SpecHelpers
    config.include MotherBrain::Mixin::Services

    config.mock_with :rspec
    config.treat_symbols_as_metadata_keys_with_true_values = true
    config.filter_run focus: true
    config.run_all_when_everything_filtered = true

    config.before(:all) do
      MB::Logging.setup(location: '/dev/null')

      @config = generate_valid_config
      @app    = MB::Application.run!(@config)
    end

    config.before(:each) do
      clean_tmp_path
    end
  end
end

if jruby?
  setup_rspec
else
  require 'spork'

  Spork.prefork do
    setup_rspec
    require 'celluloid'
    require 'dcell'
    DCell.start id: "rspec", addr: "tcp://127.0.0.1:27410"
  end

  Spork.each_run do
    require 'motherbrain'

    # Required to ensure Celluloid boots properly on each run
    Celluloid::Notifications::Fanout.supervise_as :notifications_fanout
    Celluloid::IncidentReporter.supervise_as :default_incident_reporter, STDERR
  end
end
