require 'spec_helper'

describe MB::Plugin do
  describe "ClassMethods" do
    subject { MB::Plugin }

    describe "::load" do
      let(:data) do
        proc {
          name 'reset'
          version '1.2.3'
          description 'a good plugin'
          author 'Jamie Winsor'
          email 'jamie@vialstudios.com'
        }
      end

      it "returns an instance of MB::Plugin" do
        subject.load(@context, &data).should be_a(MB::Plugin)
      end

      it "sets the evaluated value for name" do
        subject.load(@context, &data).name.should eql('reset')
      end

      it "sets the evaluated value for version" do
        subject.load(@context, &data).version.to_s.should eql('1.2.3')
      end

      it "sets the evaluated value for description" do
        subject.load(@context, &data).description.should eql('a good plugin')
      end

      it "sets the evaluated value for author" do
        subject.load(@context, &data).author.should eql('Jamie Winsor')
      end

      it "sets the evaluated value for email" do
        subject.load(@context, &data).email.should eql('jamie@vialstudios.com')
      end

      context "when the string contains an invalid Plugin description" do
        let(:data) do
          proc {
            name 1
            version '1.2.3'
          }
        end

        it "raises an PluginLoadError error" do
          lambda {
            subject.load(@context, &data)
          }.should raise_error(MB::PluginLoadError)
        end
      end
    end

    describe "::from_file" do
      let(:file) do
        tmp_path.join("pvpnet-1.2.3.rb")
      end

      let(:data) do
        <<-EOH
          name 'reset'
          version '1.2.3'
          description 'a good plugin'
          author 'Jamie Winsor'
          email 'jamie@vialstudios.com'
        EOH
      end

      before(:each) do
        File.write(file, data)
      end

      it "returns an instance of MB::Plugin" do
        subject.from_file(@context, file).should be_a(MB::Plugin)
      end

      context "when the file does not exist" do
        let(:badfile) do
          tmp_path.join("notexistant.file")
        end

        it "raises a PluginLoadError" do
          lambda {
            subject.from_file(@context, badfile)
          }.should raise_error(MB::PluginLoadError)
        end
      end
    end    
  end

  describe "DSL evaluate: cluster_bootstrap" do
    subject do
      MB::Plugin.new(@context) do
        cluster_bootstrap do
          # block
        end
      end
    end

    it "has a ClusterBootstrapper for the value of bootstrapper" do
      subject.bootstrapper.should be_a(MB::ClusterBootstrapper)
    end
  end
end
