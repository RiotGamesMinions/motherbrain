require 'spec_helper'

describe MB::Pvpnet::Cluster do
  describe "ClassMethods" do
    subject { MB::Pvpnet::Cluster }

    describe "::initialize" do
      pending
    end
  end

  let(:name) { "mb-dev" }
  let(:config) { double('config') }

  subject { MB::Pvpnet::Cluster.new(name, config) }

  describe "#start" do
    pending
  end

  describe "#stop" do
    pending
  end

  describe "#status" do
    pending
  end

  describe "#update" do
    pending
  end
end
