require 'spec_helper'

describe MB::Config do
  describe "ClassMethods" do
    subject { MB::Config }

    describe "::new" do
      before(:each) do
        @config = subject.new
      end

      it "has a default value for 'berkshelf.path'" do
        @config.berkshelf.path.should_not be_nil
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

  describe "#log.level" do
    it "converts the string 'info' to 'INFO'" do
      subject.log.level = 'info'

      subject.log.level.should eql('INFO')
    end

    it "converts the string 'debug' to 'DEBUG'" do
      subject.log.level = 'debug'

      subject.log.level.should eql('DEBUG')
    end

    it "converts the string 'warn' to 'WARN'" do
      subject.log.level = 'warn'

      subject.log.level.should eql('WARN')
    end

    it "converts the string 'fatal' to 'FATAL'" do
      subject.log.level = 'fatal'

      subject.log.level.should eql('FATAL')
    end

    it "accepts the Logger::DEBUG constant" do
      subject.log.level = Logger::DEBUG

      subject.log.level.should eql('DEBUG')
    end

    it "accepts the Logger::INFO constant" do
      subject.log.level = Logger::INFO

      subject.log.level.should eql('INFO')
    end

    it "accepts the Logger::WARN constant" do
      subject.log.level = Logger::WARN

      subject.log.level.should eql('WARN')
    end

    it "accepts the Logger::FATAL constant" do
      subject.log.level = Logger::FATAL

      subject.log.level.should eql('FATAL')
    end
  end

  describe "#log.location" do
    it "accepts the string 'stdout'" do
      subject.log.location = 'stdout'

      subject.log.location.should eql('STDOUT')
    end

    it "accepts the string 'stderr'" do
      subject.log.location = 'stderr'

      subject.log.location.should eql('STDERR')
    end
  end

  describe "validations" do
    context "given a valid configuration" do
      it "should be valid" do
        subject.should be_valid
      end
    end

    it "is invalid if berkshelf.path is blank" do
      subject.berkshelf.path = nil

      subject.should_not be_valid
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
          }.should raise_error(MB::ConfigNotFound)
        end
      end
    end

    describe "::default_path" do
      after(:each) do
        ENV['MB_CONFIG'] = nil
      end

      subject { described_class.default_path }

      it "returns a string" do
        subject.should be_a(String)
      end

      it "is located within the motherbrain file system" do
        subject.should include(MB::FileSystem.root.to_s)
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

  describe "#winrm" do
    subject { winrm }

    let(:winrm) { mb_config[:winrm] }
    let(:mb_config) {
      MB::Config.new.tap do |o|
        o.winrm.user = "Administrator"
        o.winrm.password = "secret"
      end
    }

    it { should eq(mb_config.winrm) }

    it "has valid config options" do
      expect(winrm.user).to eq("Administrator")
      expect(winrm.password).to eq("secret")
      expect(winrm.port).to eq(5985)
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
    let(:config) do
      MB::Config.new.tap do |o|
        o.chef.api_url = "https://api.opscode.com/organizations/vialstudios"
        o.chef.api_client = "reset"
        o.chef.api_key = "/Users/reset/.chef/reset.pem"
        o.chef.encrypted_data_bag_secret_path = File.join(fixtures_path, "fake_key.pem")
      end
    end

    subject do
      config.to_ridley
    end

    it "returns a hash with a 'server_url' key mapping to chef.api_url" do
      subject.should have_key(:server_url)
      subject[:server_url].should eql(config.chef.api_url)
    end

    it "returns a hash with a 'client_name' key mapping to chef.api_client" do
      subject.should have_key(:client_name)
      subject[:client_name].should eql(config.chef.api_client)
    end

    it "returns a hash with a 'client_key' key mapping to chef.api_key" do
      subject.should have_key(:client_key)
      subject[:client_key].should eql(config.chef.api_key)
    end

    it "returns a hash with a 'encrypted_data_bag_secret_path' key mapping to chef.encrypted_data_bag_secret_path" do
      subject.should have_key(:encrypted_data_bag_secret_path)
      subject[:encrypted_data_bag_secret_path].should eql(config.chef.encrypted_data_bag_secret_path)
    end

    it "returns a hash with a 'ssl.verify' key" do
      subject.should have_key(:ssl)
      subject[:ssl][:verify].should_not be_nil
    end

    it "returns a hash with a 'ssh' key" do
      subject.should have_key(:ssh)
    end

    it "returns a hash with a 'winrm' key" do
      subject.should have_key(:winrm)
    end

    describe "'ssh' key" do
      it { subject[:ssh].should eql(config.ssh) }
    end

    it "returns a hash with a 'validator_client' key mapping to chef.validator_client" do
      subject.should have_key(:validator_client)
      subject[:validator_client].should eql(config.chef.validator_client)
    end

    context "given the config has no value for organization" do
      subject do
        MB::Config.new.tap do |o|
          o.chef.api_url = "https://api.opscode.com"
          o.chef.api_client = "reset"
          o.chef.api_key = "/Users/reset/.chef/reset.pem"
        end.to_ridley
      end

      it "returns a hash without an 'organization' key" do
        subject.should_not have_key(:organization)
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
end
