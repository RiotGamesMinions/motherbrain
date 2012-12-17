require 'spec_helper'

describe MB::Upgrade::Manager do
  let(:environment) { "environment" }
  let(:plugin) { MB::Plugin.new }
  let(:options) { Hash.new }

  let(:worker_stub) { stub MB::Upgrade::Worker }

  describe "#upgrade" do
    let(:upgrade) { klass.new.upgrade environment, plugin, options }

    it "delegates to a worker" do
      MB::Upgrade::Worker.should_receive(
        :new
      ).with(
        environment, plugin, options
      ).and_return(
        worker_stub
      )

      worker_stub.should_receive :run

      upgrade
    end
  end
end
