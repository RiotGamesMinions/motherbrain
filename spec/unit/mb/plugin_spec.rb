require 'spec_helper'

describe MB::Plugin do
  describe "ClassMethods" do
    subject { MB::Plugin }

    describe "::load" do
      subject(:plugin) {
        described_class.load(&data)
      }

      let(:data) {
        proc {
          name 'reset'
          version '1.2.3'
          description 'a good plugin'
          author 'Jamie Winsor'
          email 'jamie@vialstudios.com'
        }
      }

      its(:name) { should eql('reset') }
      its(:version) { subject.to_s.should eql('1.2.3') }
      its(:description) { should eql('a good plugin') }
      its(:author) { should eql('Jamie Winsor') }
      its(:email) { should eql('jamie@vialstudios.com') }

      context "when the string contains an invalid Plugin description" do
        let(:data) {
          proc {
            name 1
            version '1.2.3'
          }
        }

        it { -> { plugin }.should raise_error MB::PluginSyntaxError }
      end

      context "with an unknown command" do
        let(:data) {
          proc {
            wat do
              huh
            end
          }
        }

        it { -> { plugin }.should raise_error MB::PluginSyntaxError }
      end
    end

    describe "::from_file" do
      subject(:plugin) {
        described_class.from_file(file)
      }

      let(:file) {
        tmp_path.join("pvpnet-1.2.3.rb")
      }

      let(:data) {
        <<-EOH
          name 'reset'
          version '1.2.3'
          description 'a good plugin'
          author 'Jamie Winsor'
          email 'jamie@vialstudios.com'
        EOH
      }

      before(:each) do
        File.write(file, data)
      end

      it { should be_a MB::Plugin }

      context "when the file does not exist" do
        let(:badfile) do
          tmp_path.join("notexistant.file")
        end

        it "raises a PluginLoadError" do
          lambda {
            described_class.from_file(badfile)
          }.should raise_error(MB::PluginLoadError)
        end
      end
    end
  end

  describe "DSL evaluate: cluster_bootstrap" do
    subject do
      MB::Plugin.new do
        cluster_bootstrap do
          # block
        end
      end
    end

    it "has a Bootstrap::Routine for the value of bootstrap_routine" do
      subject.bootstrap_routine.should be_a(MB::Bootstrap::Routine)
    end
  end

  describe "#to_s" do
    subject do
      described_class.new do
        name "pvpnet"
        version "1.2.3"
      end
    end

    it "returns the name and version of the plugin" do
      subject.to_s.should eql("pvpnet (1.2.3)")
    end
  end

  describe "comparing plugins" do
    let(:one) do
      described_class.new do
        name 'apple'
        version '1.0.0'
      end
    end
    let(:two) do
      described_class.new do
        name 'apple'
        version '2.0.0'
      end
    end
    let(:three) do
      described_class.new do
        name 'cherry'
        version '1.0.0'
      end
    end
    let(:four) do
      described_class.new do
        name 'cherry'
        version '2.0.0'
      end
    end
    let(:five) do
      described_class.new do
        name 'orange'
        version '1.0.0'
      end
    end
    let(:six) do
      described_class.new do
        name 'orange'
        version '2.0.0'
      end
    end

    let(:list) do
      [
        one,
        two,
        three,
        four,
        five,
        six
      ]
    end

    it "returns the list in the proper order" do
      list.shuffle.sort.should eql(list)
    end
  end
end
