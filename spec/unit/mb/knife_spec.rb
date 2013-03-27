require 'spec_helper'

describe MotherBrain::Knife do
  subject(:knife) { described_class.new(path) }

  let(:path) { nil }
  let(:file_contents) {
    <<-KNIFE
      user "root"
      pass "secret"
      mode :none
      variable = 123
    KNIFE
  }

  before do
    knife.stub(
      file_contents: file_contents
    )
  end

  describe "#parse" do
    before { knife.parse }

    it "parses each line and creates a key in the hash" do
      expect(knife[:user]).to eq("root")
      expect(knife[:pass]).to eq("secret")
      expect(knife[:mode]).to eq(:none)

      expect(knife[:variable]).to be_nil
    end
  end
end
