require 'spec_helper'

describe MotherBrain::ErrorHandler do
  subject { error_handler }

  let(:error_handler) { klass.new error_class, options }

  let(:error_class) { ZeroDivisionError }
  let(:options) {
    {
      caller_array: caller_array,
      method_name: method_name,
      name: name,
      path: path,
      text: text,
      version: version
    }
  }

  let(:caller_array) { nil }
  let(:method_name) { nil }
  let(:name) { nil }
  let(:path) { nil }
  let(:text) { nil }
  let(:version) { nil }

  it { should be_a klass }

  describe "#message" do
    subject(:message) { error_handler.message }

    it { should be_a String }

    context "with all options" do
      let(:caller_array) {
        ["(eval):123:in `block in from_file'"]
      }
      let(:method_name) { :wat }
      let(:name) { "abc" }
      let(:version) { "1.2.3" }
      let(:path) { "/a/b/c.rb" }
      let(:text) { "There was an error" }

      it {
        message.should == <<-MESSAGE.gsub(/^\s+/, '').strip
         abc (1.2.3)
         /a/b/c.rb, on line 123, in 'wat'
         There was an error
        MESSAGE
      }
    end

    context "with a caller array" do
      let(:caller_array) {
        ["(eval):123:in `block in from_file'"]
      }

      it { should include "line 123" }
    end

    context "with a method name" do
      let(:method_name) { :wat }

      it { should include method_name.to_s }
    end

    context "with a name and version" do
      let(:name) { "abc" }
      let(:version) { "1.2.3" }

      it { should include "abc (1.2.3)" }
    end

    context "with a path" do
      let(:path) { "/a/b/c.rb" }

      it { should include path }
    end

    context "with text" do
      let(:text) { "There was an error" }

      it { should include text }
    end
  end

  describe "#render" do
    subject { error_handler.render }

    it { -> { subject }.should raise_error error_class }
  end

  describe "#line_number" do
    subject { error_handler.line_number }

    let(:caller_array) { [line] }

    context "with an eval'd line" do
      let(:line) { "(eval):123:in `block in from_file'" }

      it { should == 123 }
    end

    context "with an sourced line" do
      let(:line) { "/Users/JohnDoe/a/b/c.rb:123:in `method'" }

      it { should == 123 }
    end
  end
end
