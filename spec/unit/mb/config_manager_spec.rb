require 'spec_helper'

describe MB::ConfigManager do
  subject { described_class.new(@config) }

  describe "update" do
    let(:listener) do
      Class.new do
        include Celluloid
        include Celluloid::Notifications
      end.new
    end

    let(:new_config) do
      double('config', validate!: true)
    end

    it "sends the 'config_manager.configure' notification" do
      listener.subscribe('config_manager.configure', :trigger)
      listener.should_receive(:trigger).once

      subject.update(new_config)
    end

    it "updates the config attribute with the given config" do
      subject.update(new_config)

      subject.config.should eql(new_config)
    end
  end
end
