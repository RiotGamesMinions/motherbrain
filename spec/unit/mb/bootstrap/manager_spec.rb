require 'spec_helper'

describe MB::Bootstrap::Manager do
  describe "ClassMethods" do
    subject { described_class }

    describe "::validate_options" do
      let(:valid_options) do
        {
          server_url: "test",
          client_name: "test",
          client_key: "test",
          validator_client: "test",
          validator_path: "test",
          ssh_user: "test",
          ssh_keys: "test",
          ssh_password: "test"
        }
      end

      it "raises an ArgumentError if any of the required options is not provided" do
        valid_options.keys.each do |opt|
          options = valid_options.dup
          options.delete(opt)
          
          expect { subject.validate_options(options) }.to raise_error(MB::ArgumentError)
        end
      end

      it "raises an ArgumentError if any of the required options have a nil value" do
        valid_options.keys.each do |opt|
          options = valid_options.dup
          options[opt] = nil

          expect { subject.validate_options(options) }.to raise_error(MB::ArgumentError)
        end
      end
    end
  end

  let(:plugin) do
    MB::Plugin.new(@context) do
      name "pvpnet"
      version "1.2.3"

      component "activemq" do
        group "master"
        group "slave"
      end

      component "nginx" do
        group "master"
      end
    end
  end

  let(:manifest) do
    MB::Bootstrap::Manifest.new(
      nil,
      "activemq::master" => [
        "amq1.riotgames.com",
        "amq2.riotgames.com"
      ],
      "activemq::slave" => [
        "amqs1.riotgames.com",
        "amqs2.riotgames.com"
      ],
      "nginx::master" => [
        "nginx1.riotgames.com"
      ]
    )
  end

  let(:routine) do
    MB::Bootstrap::Routine.new(@context, plugin) do
      async do
        bootstrap("activemq::master")
        bootstrap("activemq::slave")
      end

      bootstrap("nginx::master")
    end
  end

  let(:bootstrap_options) do
    {
      server_url: "https://api.opscode.com/organizations/vialstudios",
      client_name: "reset",
      client_key: fixtures_path.join("fake_key.pem").to_s,
      validator_client: "fake-validator",
      validator_path: fixtures_path.join("fake_key.pem").to_s,
      ssh_user: "reset",
      ssh_keys: fixtures_path.join("fake_id_rsa").to_s
    }
  end

  subject { described_class.new }

  before(:each) do
    stub_request(:get, "https://api.opscode.com/organizations/vialstudios/nodes").
      to_return(status: 200, body: {})
  end

  describe "#bootstrap" do
    it "returns an array of hashes" do
      result = subject.bootstrap(manifest, routine, bootstrap_options)

      result.should be_a(Array)
      result.should each be_a(Hash)
    end

    it "returns an item for every item in the task_queue" do
      subject.bootstrap(manifest, routine, bootstrap_options).should have(2).items
    end

    it "returns items where each is a hash with a key for each node group of each task_queue item" do
      result = subject.bootstrap(manifest, routine, bootstrap_options)

      result[0].should have_key("activemq::master")
      result[0].should have_key("activemq::slave")
      result[1].should have_key("nginx::master")
    end

    it "has a Ridley::SSH::ResponseSet for each value" do
      result = subject.bootstrap(manifest, routine, bootstrap_options)

      result[0]["activemq::master"].should be_a(Ridley::SSH::ResponseSet)
      result[0]["activemq::slave"].should be_a(Ridley::SSH::ResponseSet)
      result[1]["nginx::master"].should be_a(Ridley::SSH::ResponseSet)
    end
  end
end
