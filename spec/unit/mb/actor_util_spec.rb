require 'spec_helper'

describe MB::ActorUtil do
  subject do
    Class.new do
      include MB::ActorUtil
    end.new
  end

  describe "#safe_return" do
    let(:result) do
      subject.safe_return { 1 + 1 }
    end

    it "returns an array" do
      result.should be_a(Array)
    end

    it "contains two elements" do
      result.should have(2).items
    end

    context "when no exception is thrown" do
      it "has the symbol :ok at index 0" do
        result[0].should eql(:ok)
      end

      it "has the result of the block at index 1" do
        result[1].should eql(2)
      end
    end

    context "when an exception is thrown" do
      let(:exception) { ArgumentError.new("my error message") }
      let(:result) do
        subject.safe_return { raise exception }
      end

      it "has the symbol :error at index 0" do
        result[0].should eql(:error)
      end

      it "has the exception at index 1" do
        result[1].should eql(exception)
      end
    end

    context "given explicit types to catch" do
      it "returns an error result for only those exceptions" do
        subject.safe_return(ArgumentError, TypeError) { raise TypeError }.first.should eql(:error)
        subject.safe_return(ArgumentError, TypeError) { raise ArgumentError }.first.should eql(:error)
      end

      it "raises if the raise exception is not to be caught" do
        expect {
          subject.safe_return(ArgumentError, TypeError) { raise NameError }
        }.to raise_error(NameError)
      end
    end

    context "given no arguments" do
      it "catches anything inheriting from ::Exception" do
        subject.safe_return { raise ::Exception }.first.should eql(:error)
      end
    end

    context "given no block" do
      it "raises an LocalJumpError" do
        expect {
          subject.safe_return
        }.to raise_error(LocalJumpError)
      end
    end
  end
end
