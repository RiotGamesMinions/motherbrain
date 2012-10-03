require 'spec_helper'

describe MB::ProxyObject do
  describe "ClassMethods" do
    subject do
      Class.new do
        include MB::ProxyObject
      end
    end

    describe "::new" do
      context "when no block is given" do
        it "raises PluginSyntaxError" do
          lambda {
            subject.new(@context)
          }.should raise_error(MB::PluginSyntaxError)
        end
      end
    end
  end
end
