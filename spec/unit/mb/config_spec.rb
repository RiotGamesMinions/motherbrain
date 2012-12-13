require 'spec_helper'

describe MB::Config do
  describe "ClassMethods" do
    subject { MB::Config }

    describe "::new" do
      before(:each) do
        @config = subject.new
      end

      it "has a default value for chef.api_url" do
        @config.chef.api_url.should eql("http://localhost:8080")
      end

      it "has a default value for plugin_paths equal to PluginManager.default_paths" do
        @config.plugin_paths.should eql(MB::PluginManager.default_paths)
      end
    end

    describe "::validate!" do
      it "raises an InvalidConfig error if the given config is invalid" do
        invalid_config = double('config', valid?: false, errors: [])

        expect {
          subject.validate!(invalid_config)
        }.to raise_error(MB::InvalidConfig)
      end
    end

    describe "::manager" do
      it "returns an instance of MB::ConfigManager" do
        subject.manager.should be_a(MB::ConfigManager)
      end
    end
  end

  subject do
    MB::Config.new.tap do |o|
      o.chef.api_url = "https://api.opscode.com/organizations/vialstudio"
      o.chef.api_client = "reset"
      o.chef.api_key = "/Users/reset/.chef/reset.pem"
      o.ssh.user = "root"
      o.ssh.password = "something"
    end
  end

  describe "validations" do
    context "given a valid configuration" do
      it "should be valid" do
        subject.should be_valid
      end
    end

    it "is invalid if chef.api_url is blank" do
      subject.chef.api_url = nil

      subject.should_not be_valid
    end

    it "is invalid if chef.api_url is not a valid HTTP or HTTPS url" do
      pending
      
      subject.chef.api_url = 'not_a_uri'

      subject.should_not be_valid
    end

    it "is invalid if chef.api_client is blank" do
      subject.chef.api_client = nil

      subject.should_not be_valid
    end

    it "is invalid if chef.api_key is blank" do
      subject.chef.api_key = nil

      subject.should_not be_valid
    end

    it "is invalid if ssh_keys is blank or empty and ssh_password is blank" do
      pending

      subject.ssh.keys = []
      subject.ssh.password = ''

      subject.should_not be_valid
      subject.errors[:ssh_password].should =~ ["You must specify an SSH password or an SSH key"]
      subject.errors[:ssh_keys].should =~ ["You must specify an SSH password or an SSH key"]
    end

    it "is invalid if ssh_timeout is a non-integer non-float" do
      subject.ssh.timeout = "string"

      subject.should_not be_valid
    end

    it "is valid if ssh_timeout is an integer" do
      subject.ssh.timeout = 1

      subject.should be_valid
    end

    it "is valid if ssh_timeout is a float" do
      subject.ssh.timeout = 1.0

      subject.should be_valid
    end
  end

  let(:json) do
    %(
      {
        "chef": {
          "api_client": "reset"
        }
      }
    )
  end

  describe "ClassMethods" do
    subject { MB::Config }

    describe "::from_json" do
      it "returns an instance of MB::Config" do
        subject.from_json(json).should be_a(MB::Config)
      end
    end

    describe "::from_file" do
      let(:file) { tmp_path.join("test-config.json").to_s }

      before(:each) do
        File.write(file, json)
      end

      it "returns an instance of MB::Config" do
        subject.from_file(file).should be_a(MB::Config)
      end

      it "sets the object's path to the path of the loaded file" do
        subject.from_file(file).path.should eql(file)
      end

      context "given a file that does not exist" do
        it "raises a MB::ConfigNotFound error" do
          lambda {
            subject.from_file(tmp_path.join("asdf.txt"))
          }.should raise_error(Chozo::Errors::ConfigNotFound)
        end
      end
    end

    describe "::default_path" do
      after(:each) do
        ENV['MB_CONFIG'] = nil
      end

      it "returns the value of ENV['MB_CONFIG'] if the environment variable is set" do
        ENV['MB_CONFIG'] = "/tmp/config.json"

        subject.default_path.should eql("/tmp/config.json")
      end

      it "returns expanded ~/.mb/config.json if ENV['MB_CONFIG'] is not set" do
        subject.default_path.should eql(File.expand_path("~/.mb/config.json"))
      end
    end
  end

  describe "#from_json" do
    it "sets the attributes found in the json" do
      subject.from_json(json).chef.api_client.should eql("reset")
    end

    context "given JSON containing undefined attributes" do
      let(:json) do
        %(
          {
            "not_a_valid_attribute": "failure!"
          }
        )
      end

      it "ignores the additional configuration options" do
        subject.from_json(json).should_not respond_to(:not_a_valid_attribute)
      end
    end

    context "given malformed JSON" do
      let(:json) do
        %(
          {
            "firstkey": "firstval"
            "missing": "a comma"
          }
        )
      end

      it "raises an InvalidConfiguration error" do
        lambda {
          subject.from_json(json).attributes
        }.should raise_error(Chozo::Errors::InvalidConfig)
      end
    end
  end

  describe "#to_json" do
    it "should not include the 'id' attribute" do
      subject.to_json.should_not have_json_path('id')
    end
  end

  describe "#save" do
    let(:config_path) { tmp_path.join("config.json") }

    before(:each) { subject.path = config_path }

    it "creates a new file at the instance's path" do
      subject.save

      config_path.should exist
    end

    it "writes the evaluation of to_json as the content of the file" do
      subject.save

      File.read(config_path).should be_json_eql(subject.to_json)
    end
  end

  describe "#to_ridley" do
    subject do
      MB::Config.new.tap do |o|
        o.chef.api_url = "https://api.opscode.com"
        o.chef.api_client = "reset"
        o.chef.api_key = "/Users/reset/.chef/reset.pem"
        o.chef.organization = "vialstudios"
        o.chef.encrypted_data_bag_secret_path = File.join(fixtures_path, "fake_key.pem")
      end
    end

    it "returns a hash with a 'server_url' key mapping to chef.api_url" do
      obj = subject.to_ridley

      obj.should have_key(:server_url)
      obj[:server_url].should eql(subject.chef.api_url)
    end

    it "returns a hash with a 'client_name' key mapping to chef.api_client" do
      obj = subject.to_ridley

      obj.should have_key(:client_name)
      obj[:client_name].should eql(subject.chef.api_client)
    end

    it "returns a hash with a 'client_key' key mapping to chef.api_key" do
      obj = subject.to_ridley

      obj.should have_key(:client_key)
      obj[:client_key].should eql(subject.chef.api_key)
    end

    it "returns a hash with a 'encrypted_data_bag_secret_path' key mapping to chef.encrypted_data_bag_secret_path" do
      obj = subject.to_ridley

      obj.should have_key(:encrypted_data_bag_secret_path)
      obj[:encrypted_data_bag_secret_path].should eql(subject.chef.encrypted_data_bag_secret_path)
    end

    it "returns a hash with an 'organization' key mapping to chef.organization" do
      obj = subject.to_ridley

      obj.should have_key(:organization)
      obj[:organization].should eql(subject.chef.organization)
    end

    it "returns a hash with a 'ssl.verify' key" do
      obj = subject.to_ridley

      obj.should have_key(:ssl)
      obj[:ssl][:verify].should_not be_nil
    end

    context "given the config has no value for organization" do
      subject do
        MB::Config.new.tap do |o|
          o.chef.api_url = "https://api.opscode.com"
          o.chef.api_client = "reset"
          o.chef.api_key = "/Users/reset/.chef/reset.pem"
        end
      end

      it "returns a hash without an 'organization' key" do
        subject.to_ridley.should_not have_key(:organization)
      end
    end
  end

  describe "#to_rest_gateway" do
    subject { MB::Config.new }

    it "returns a hash containing a 'host' key and value" do
      subject.to_rest_gateway.should have_key(:host)
      subject.to_rest_gateway[:host].should_not be_nil
    end

    it "returns a hash containing a 'port' key and value" do
      subject.to_rest_gateway.should have_key(:port)
      subject.to_rest_gateway[:port].should_not be_nil
    end
  end

  describe "#to_rest_client" do
    subject { MB::Config.new }

    it "returns a hash containing a 'url' key and value" do
      subject.to_rest_client.should have_key(:url)
      subject.to_rest_client[:url].should_not be_nil
    end
  end
end
