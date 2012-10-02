require 'spec_helper'

describe MB::Context do
  let(:chef_conn) { double('conn') }
  let(:config) { double('config', to_ridley: chef_conn) }
  let(:nexus_conn) { double('nexus_conn') }

  describe "ClassMethods" do
    subject { MB::Context }

    describe "::new" do
      it "assigns the given config to the config attribute" do
        subject.new(config).config.should eql(config)
      end

      it "assigns additional given attributes to methods" do
        subject.new(config, nexus_conn: nexus_conn).nexus_conn.should eql(nexus_conn)
      end

      context "when an additional attribute 'config' is given" do
        it "does not overwrite the config attribute set from the config parameter" do
          subject.new(config, config: "asdf").config.should eql(config)
        end
      end
    end
  end

  subject { MB::Context.new(config) }

  it "allows additional attributes to be dynamically set" do
    subject.nexus_conn = nexus_conn
    
    subject.nexus_conn.should eql(nexus_conn)
  end

  describe "#chef_conn" do
    it "delegates to_ridley to config" do
      config.should_receive(:to_ridley)

      subject.chef_conn.should eql(chef_conn)
    end
  end
end
