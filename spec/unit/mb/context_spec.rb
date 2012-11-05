require 'spec_helper'

describe MotherBrain::Context do
  describe "ClassMethods" do
    subject { MotherBrain::Context }

    describe "::new" do
      it "assigns the given config to the config attribute" do
        subject.new(@config).config.should eql(@config)
      end

      it "assigns additional given attributes to methods" do
        obj = subject.new(@config, thinger: "value")

        obj.should respond_to(:thinger)
        obj.thinger.should eql("value")
      end

      context "when an additional attribute 'config' is given" do
        it "does not overwrite the config attribute set from the config parameter" do
          subject.new(@config, config: "asdf").config.should eql(@config)
        end
      end
    end
  end

  subject { MotherBrain::Context.new(@config) }

  it "allows dynamic attribute assignment and retrieval" do
    subject.thingy = "some_value"

    subject.thingy.should eql("some_value")
  end

  describe "#chef_conn" do
    it "returns a Ridley::Connection" do
      subject.chef_conn.should be_a(Ridley::Connection)
    end
  end
end
