require 'spec_helper'

describe MB::Provisioners::EnvironmentFactory do
  let(:manifest) do
    MB::Provisioner::Manifest.new.from_json({
      "x1.large" => {
        "activemq::master" => 4,
        "activemq::slave" => 2
      },
      "x1.small" => {
        "nginx::server" => 2
      }
    }.to_json)
  end

  describe "ClassMethods" do
    subject { described_class }

    describe "::convert_manifest" do
      it "returns an array of hashes" do
        subject.convert_manifest(manifest).should be_a(Array)
        subject.convert_manifest(manifest).should each be_a(Hash)
      end

      it "contains an element for the amount of each node group and instance type" do
        subject.convert_manifest(manifest).should have(8).items
      end
    end
  end

  let(:options) do
    {
      api_url: "https://ef.riotgames.com",
      api_key: "58dNU5xBxDKjR15W71Lp",
      ssl: {
        verify: false
      }
    }
  end

  subject { described_class.new(options) }

  describe "#up" do
    let(:env_name) { "mbtest" }

    it "creates an environment with the given name and converted manifest" do
      connection = double('connection')
      environment = double('environment')
      converted_manifest = double('converted_manifest')
      described_class.should_receive(:convert_manifest).with(manifest).and_return(converted_manifest)
      connection.stub_chain(:environment, :create).with(env_name, converted_manifest).and_return(Hash.new)
      connection.stub_chain(:environment, :created?).with(env_name).and_return(true)
      connection.stub_chain(:environment, :find).with(env_name).and_return(environment)
      subject.connection = connection

      subject.up(env_name, manifest)
    end
  end

  describe "#down" do
    let(:env_name) { "mbtest" }

    it "sends a destroy command to environment factory with the given environment" do
      connection = double('connection')
      connection.stub_chain(:environment, :destroy).with(env_name).and_return(Hash.new)
      subject.connection = connection

      subject.down(env_name)
    end
  end
end
