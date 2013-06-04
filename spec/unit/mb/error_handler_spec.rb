require 'spec_helper'

describe MotherBrain::ErrorHandler do
  subject { error_handler }

  let(:error_handler) { klass.new error, options }

  let(:error) { ZeroDivisionError.new }
  let(:options) {
    {
      backtrace: backtrace,
      method_name: method_name,
      plugin_name: plugin_name,
      file_path: file_path,
      plugin_version: plugin_version,
      text: text
    }
  }

  let(:backtrace) { nil }
  let(:method_name) { nil }
  let(:plugin_name) { nil }
  let(:file_path) { nil }
  let(:plugin_version) { nil }
  let(:text) { nil }

  it { should be_a klass }

  context "when passed an error class" do
    let(:error) { ZeroDivisionError }

    its(:error) { should be_instance_of error }
  end

  describe "#message" do
    subject(:message) { error_handler.message }

    it { should be_a String }

    context "with all options" do
      let(:backtrace) {
        ["(eval):123:in `block in from_file'"]
      }
      let(:method_name) { :wat }
      let(:plugin_name) { "abc" }
      let(:file_path) { "/a/b/c.rb" }
      let(:plugin_version) { "1.2.3" }
      let(:text) { "There was an error" }

      it {
        message.should == <<-MESSAGE.gsub(/^\s+/, '')
         abc (1.2.3)
         /a/b/c.rb, on line 123, in 'wat'
         There was an error
        MESSAGE
      }
    end

    context "with a caller array" do
      let(:backtrace) {
        ["(eval):123:in `block in from_file'"]
      }

      it { should include "line 123" }
    end

    context "with a method name" do
      let(:method_name) { :wat }

      it { should include method_name.to_s }
    end

    context "with a name and version" do
      let(:plugin_name) { "abc" }
      let(:plugin_version) { "1.2.3" }

      it { should include "abc (1.2.3)" }
    end

    context "with a path" do
      let(:file_path) { "/a/b/c.rb" }

      it { should include file_path }
    end

    context "with text" do
      let(:text) { "There was an error" }

      it { should include text }
    end
  end

  describe ".wrap" do
    subject { klass.wrap error, options }

    it { -> { subject }.should raise_error error.class }
  end

  describe "#line_number" do
    subject { error_handler.line_number }

    let(:backtrace) { [line] }

    context "with an eval'd line" do
      let(:line) { "(eval):123:in `block in from_file'" }

      it { should == 123 }
    end

    context "with a sourced line" do
      let(:line) { "/Users/JohnDoe/a/b/c.rb:123:in `method'" }

      it { should == 123 }
    end
  end

  describe "#file_contents" do
    subject { error_handler.file_contents }

    let(:file_contents) { "abc123" }
    let(:file_path) { "/a/b/c.rb" }

    before :each do
      File.stub(:exist?).with(file_path).and_return(true)
      File.stub(:read).with(file_path).and_return(file_contents)
    end

    it { should == file_contents }

    context "with no file_path" do
      let(:file_path) { nil }

      it { should be_nil }
    end
  end

  describe "#relevant_source_lines" do
    subject { error_handler.relevant_source_lines }

    let(:backtrace) { ["something:6:something"] }
    let(:file_contents) {
      <<-FILE.gsub(/^\s{8}/, '')
        require 'motherbrain'

        module MyModule
          class MyClass
            def my_method
              do :one
              do :two
              do :three
            end
          end
        end
      FILE
    }
    let(:file_path) { "/a/b/c.rb" }

    before :each do
      File.stub(:exist?).with(file_path).and_return(true)
      File.stub(:read).with(file_path).and_return(file_contents)
    end

    it {
      should == <<-OUTPUT.gsub(/^\s{8}/, '').rstrip
         4:     def my_method
         5:       do :one
         6>>      do :two
         7:       do :three
         8:     end
      OUTPUT
    }
  end
end
