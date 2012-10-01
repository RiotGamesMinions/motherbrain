require 'spec_helper'

describe MB::PluginDSL::Commands do
  subject do
    Class.new do
      include MB::PluginDSL::Commands
    end.new
  end

  describe "#command" do
    context "when no block is given" do
      it "raises a PluginSyntaxError" do
        lambda {
          subject.command
        }.should raise_error(MB::PluginSyntaxError)
      end
    end
  end
end
