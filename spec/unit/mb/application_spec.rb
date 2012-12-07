require 'spec_helper'

describe MB::Application do
  describe "ClassMethods" do
    subject { described_class }

    describe "::run!" do
      before(:each) do
        @app = subject.run!(@config)
      end

      after(:each) do
        @app.terminate
      end

      it "starts an actor and registers it as 'provisioner_manager'" do
        Celluloid::Actor[:provisioner_manager].should_not be_nil
      end

      it "starts an actor and registers it as 'bootstrap_manager'" do
        Celluloid::Actor[:bootstrap_manager].should_not be_nil
      end

      it "starts an actor and registers it as 'node_querier'" do
        Celluloid::Actor[:node_querier].should_not be_nil
      end

      it "gives a chef_conn to 'node_querier'" do
        Celluloid::Actor[:node_querier].chef_conn.should be_a(Ridley::Connection)
      end
    end

    describe "::validate_config!" do
      it "raises an InvalidConfig error if the given config is invalid" do
        invalid_config = double('config', valid?: false, errors: [])

        expect {
          subject.validate_config!(invalid_config)
        }.to raise_error(MB::InvalidConfig)
      end
    end
  end

  subject { described_class.new }

  describe "#configure" do
    before(:each) { subject.configure(@config) }

    after(:each) do
      subject.terminate if subject.alive?
    end

    it "sets the value of config to the given config" do
      subject.config.should eql(@config)
    end

    it "sets the value of chef_conn to a Ridley::Connection" do
      subject.chef_conn.should be_a(Ridley::Connection)
    end
  end
end
