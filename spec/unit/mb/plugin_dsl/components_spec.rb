require 'spec_helper'

describe MB::PluginDSL::Components do
  subject do
    Class.new do
      include MB::PluginDSL::Components
    end.new
  end

  before(:each) do
    subject.stub(:context) { @context }
  end

  describe "#component" do
    let(:component) do
      double('component', id: 'pvpnet')
    end

    it "creates a new component and adds it to the components" do
      block = Proc.new { }
      MB::Component.should_receive(:new).with(@context, &block).and_return(component)
      subject.component(&block)

      subject.components.should have(1).item
    end

    context "when no block is given" do
      it "raises a PluginSyntaxError" do
        lambda {
          subject.component
        }.should raise_error(MB::PluginSyntaxError)
      end
    end
  end

  describe "#components" do
    it "returns an empty Hash" do
      subject.components.should be_a(Hash)
      subject.components.should be_empty
    end
  end
end
