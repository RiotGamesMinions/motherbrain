require 'spec_helper'

describe MB::Config do
  describe "ClassMethods" do
    subject { MB::Config }

    describe "::new" do
      before(:each) do
        @config = subject.new
      end

      it "has a default value for chef_api_url" do
        @config.chef_api_url.should eql("http://localhost:8080")
      end

      it "has a default value for plugin_paths equal to PluginLoader.default_paths" do
        @config.plugin_paths.should eql(MB::PluginLoader.default_paths)
      end
    end
  end

  subject do
    MB::Config.new.tap do |o|
      o.chef_api_url = "https://api.opscode.com/organizations/vialstudio"
      o.chef_api_client = "reset"
      o.chef_api_key = "/Users/reset/.chef/reset.pem"
      o.ssh_user = "root"
      o.ssh_password = "something"
    end
  end

  describe "validations" do
    context "given a valid configuration" do
      it "should be valid" do
        subject.should be_valid
      end
    end

    it "is invalid if chef_api_url is blank" do
      subject.chef_api_url = ''

      subject.should_not be_valid
    end

    it "is invalid if chef_api_url is not a valid HTTP or HTTPS url" do
      pending
      
      subject.chef_api_url = 'not_a_uri'

      subject.should_not be_valid
    end

    it "is invalid if chef_api_client is blank" do
      subject.chef_api_client = ''

      subject.should_not be_valid
    end

    it "is invalid if chef_api_key is blank" do
      subject.chef_api_key = ''

      subject.should_not be_valid
    end

    it "is invalid if the ssh_key and ssh_password is blank" do
      pending

      subject.ssh_key = ''
      subject.ssh_password = ''

      subject.should_not be_valid
      subject.errors[:ssh_password].should =~ ["You must specify an SSH password or an SSH key"]
      subject.errors[:ssh_key].should =~ ["You must specify an SSH password or an SSH key"]
    end
  end

  let(:json) do
    %(
      {
        "chef_api_client": "reset"
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

      it "returns ~/.mb/config.json if ENV['MB_CONFIG'] is not set" do
        subject.default_path.should eql("~/.mb/config.json")
      end
    end
  end

  describe "#from_json" do
    it "sets the attributes found in the json" do
      subject.from_json(json).chef_api_client.should eql("reset")
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
        o.chef_api_url = "https://api.opscode.com"
        o.chef_api_client = "reset"
        o.chef_api_key = "/Users/reset/.chef/reset.pem"
        o.chef_organization = "vialstudios"
      end
    end

    it "returns a hash with a 'server_url' key mapping to chef_api_url" do
      obj = subject.to_ridley

      obj.should have_key(:server_url)
      obj[:server_url].should eql(subject.chef_api_url)
    end

    it "returns a hash with a 'client_name' key mapping to chef_api_client" do
      obj = subject.to_ridley

      obj.should have_key(:client_name)
      obj[:client_name].should eql(subject.chef_api_client)
    end

    it "returns a hash with a 'client_key' key mapping to chef_api_key" do
      obj = subject.to_ridley

      obj.should have_key(:client_key)
      obj[:client_key].should eql(subject.chef_api_key)
    end

    it "returns a hash with an 'organization' key mapping to chef_organization" do
      obj = subject.to_ridley

      obj.should have_key(:organization)
      obj[:organization].should eql(subject.chef_organization)
    end

    context "given the config has no value for organization" do
      subject do
        MB::Config.new.tap do |o|
          o.chef_api_url = "https://api.opscode.com"
          o.chef_api_client = "reset"
          o.chef_api_key = "/Users/reset/.chef/reset.pem"
        end
      end

      it "returns a hash without an 'organization' key" do
        subject.to_ridley.should_not have_key(:organization)
      end
    end
  end
end
