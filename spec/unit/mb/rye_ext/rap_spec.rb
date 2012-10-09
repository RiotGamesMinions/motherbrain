require 'spec_helper'

describe Rye::Rap do
  let(:box) { double('box') }

  subject { Rye::Rap.new(box) }

  describe "#to_hash" do
    before(:each) do
      @rye_hash = subject.to_hash
    end

    it "returns a hash" do
      @rye_hash.should be_a(Hash)
    end

    it "has an exit_status key" do
      @rye_hash.should have_key(:exit_status)
    end

    it "has an exit_signal key" do
      @rye_hash.should have_key(:exit_signal)
    end

    it "has a stderr key" do
      @rye_hash.should have_key(:stderr)
    end

    it "has a stdout key" do
      @rye_hash.should have_key(:stdout)
    end
  end
end
