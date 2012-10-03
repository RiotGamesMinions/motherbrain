require 'spec_helper'

describe MB::PluginDSL::Dependencies do
  subject do
    Class.new do
      include MB::PluginDSL::Dependencies
    end.new
  end

  before(:each) do
    subject.context = @context
    subject.real = double('real_object')
  end

  pending
end
