ENV['RUBY_ENV'] ||= 'test'

require 'rubygems'
require 'bundler'
require 'rspec'
require 'json_spec'
require 'webmock/rspec'
require 'motherbrain'

def setup_rspec
  Dir[File.join(File.expand_path("../../spec/support/**/*.rb", __FILE__))].each { |f| require f }

  RSpec.configure do |config|
    config.include JsonSpec::Helpers
    config.include MotherBrain::SpecHelpers

    config.mock_with :rspec
    config.treat_symbols_as_metadata_keys_with_true_values = true
    config.filter_run focus: true
    config.run_all_when_everything_filtered = true

    config.before(:all) { MB.set_logger(nil) }

    config.before(:each) do
      clean_tmp_path
      @config = double('config',
        to_ridley: {
          server_url: "http://chef.riotgames.com",
          client_name: "fake",
          client_key: File.join(fixtures_path, "fake_key.pem")
        },
        ssh_user: 'reset',
        ssh_password: 'whatever',
        ssh_key: nil
      )
      @context = MB::Context.new(@config)
    end
  end
end

if jruby?
  setup_rspec
else
  require 'spork'

  Spork.prefork do
    setup_rspec
  end

  Spork.each_run do
    require 'motherbrain'
  end
end
