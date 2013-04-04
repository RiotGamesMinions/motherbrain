require 'spec_helper'

describe Signal do
  describe "#supported?" do
    let(:signal_name) { "HUP" }
    subject { described_class.supported?(signal_name) }

    context "when the signal is in the list of signals" do
      before do
        Signal.stub(list: { "HUP" => 1 })
      end

      it { should be_true }
    end

    context "when the signal is not in the list of supported signals" do
      before do
        Signal.stub(list: Hash.new)
      end

      it { should be_false }
    end
  end
end
