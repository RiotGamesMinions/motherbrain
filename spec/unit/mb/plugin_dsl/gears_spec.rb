require 'spec_helper'

describe MB::PluginDSL::Gears do
  subject do
    Class.new do
      include MB::PluginDSL::Gears
    end.new
  end

  it "responds to service" do
    subject.should respond_to(:service)
  end
end
