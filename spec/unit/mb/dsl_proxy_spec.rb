require 'spec_helper'

describe MB::DSLProxy do
  describe "ClassMethods" do
    subject do
      Class.new do
        include MB::DSLProxy
      end
    end

    describe "::new" do
      context "when no block is given" do
        it "raises PluginSyntaxError" do
          lambda {
            subject.new
          }.should raise_error(MB::PluginSyntaxError)
        end
      end
    end
  end
end
