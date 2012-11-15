require 'spec_helper'

describe MB::Provisioners::EnvironmentFactory do
  let(:options) do
    {
      api_url: "https://ef.riotgames.com",
      api_key: "58dNU5xBxDKjR15W71Lp",
      ssl: {
        verify: false
      }
    }
  end

  subject { MB::Provisioners::EnvironmentFactory.new(options) }

  describe "#run" do
    let(:env_name) { "mbtest" }
    let(:manifest) { [] }

    it "creates an environment with the given name and manifest" do
      connection = double('connection')
      environment = double('environment')
      connection.stub_chain(:environment, :create).with(env_name, manifest).and_return(Hash.new)
      connection.stub_chain(:environment, :created?).with(env_name).and_return(true)
      connection.stub_chain(:environment, :find).with(env_name).and_return(environment)
      subject.connection = connection

      subject.run(env_name, manifest)
    end
  end
end
