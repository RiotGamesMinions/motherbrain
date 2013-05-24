require 'spec_helper'

describe MB::Bootstrap::Template do
  context "ClassMethods" do
    describe "#find" do
      let(:name_or_path) { "foo" }
      subject { described_class.find(name_or_path) }

      context "with installed template" do
        before do
          File.should_receive(:exists?).
            with(MB::FileSystem.templates.join("#{name_or_path}.erb").to_s).
            and_return(true)
        end

        it "should be the path to the installed template" do
          expect(subject).to eq(MB::FileSystem.templates.join("foo.erb").to_s)
        end
      end

      context "with no installed template" do
        before do
          File.should_receive(:exists?).
            with(MB::FileSystem.templates.join("#{name_or_path}.erb").to_s).
            and_return(false)
        end

        context "with an existing path" do
          let(:name_or_path) { "/some/path/bar.erb" }

          before do
            File.should_receive(:exists?).
              with(name_or_path).and_return(true)
          end

          it "should be the passed in path" do
            expect(subject).to eq(name_or_path)
          end
        end

        context "with a non-existant path" do
          let(:name_or_path) { "/some/path/baz.erb" }

          before do
            File.should_receive(:exists?).
              with(name_or_path).and_return(false)
          end

          it "should raise" do
            expect { subject }.to raise_error(MB::BootstrapTemplateNotFound)
          end
        end
      end

      context "with no name or path" do
        let(:name_or_path) { nil }
        
        context "with a default in config" do
          before do
            MB::Application.config.bootstrap.default_template = "quux"
            File.should_receive(:exists?).
              with(MB::FileSystem.templates.join("quux.erb").to_s).
              and_return(true)
          end
          
          it "should get the default" do
            expect(subject).to eq(MB::FileSystem.templates.join("quux.erb").to_s)
          end
        end
      end
    end
  end
end
