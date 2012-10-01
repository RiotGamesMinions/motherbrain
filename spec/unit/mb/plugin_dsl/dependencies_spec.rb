require 'spec_helper'

describe MB::PluginDSL::Dependencies do
  subject do
    Class.new do
      include MB::PluginDSL::Dependencies
    end.new
  end

  pending
end
