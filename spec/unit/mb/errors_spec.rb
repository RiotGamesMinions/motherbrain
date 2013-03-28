require 'spec_helper'

describe "errors" do
  describe MB::MBError do
    let(:error) { described_class.new("rspec test message") }

    describe "#exit_code" do
      subject { error.exit_code }

      it { should be_a(Integer) }
    end

    describe "#error_code" do
      subject { error.error_code }

      it { should be_a(Integer) }
    end

    describe "#message" do
      subject { error.message }

      it { should be_a(String) }
    end

    describe "#to_s" do
      subject { error.to_s }
      
      it "includes the error code" do
        subject.should include("[err_code]: #{error.error_code}")
      end

      it "includes the error message" do
        subject.should include("[message]: #{error.message}")
      end
    end

    describe "#to_hash" do
      subject { error.to_hash }

      it "contains an :code key with the exceptions error_code for it's value" do
        subject.should have_key(:code)
        subject[:code].should eql(error.error_code)
      end

      it "contains a :message key with the exceptions message for it's value" do
        subject.should have_key(:message)
        subject[:message].should eql(error.message)
      end
    end

    describe "#to_json" do
      subject { error.to_json }
      
      it { should have_json_path("code") }
      it { should have_json_path("message") }
    end
  end
end
