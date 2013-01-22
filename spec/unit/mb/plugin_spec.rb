require 'spec_helper'

describe MB::Plugin do
  let(:metadata) do
    MB::CookbookMetadata.new do
      name             "motherbrain"
      maintainer       "Jamie Winsor"
      maintainer_email "jamie@vialstudios.com"
      license          "Apache 2.0"
      description      "Installs/Configures motherbrain"
      long_description "Installs/Configures motherbrain"
      version          "0.1.0"
    end
  end

  describe "ClassMethods" do
    subject { MB::Plugin }

    describe "::load" do
      subject(:plugin) do
        described_class.load(metadata) do
          # blank plugin
        end
      end

      its(:name) { should eql('motherbrain') }
      its(:maintainer) { should eql('Jamie Winsor') }
      its(:maintainer_email) { should eql('jamie@vialstudios.com') }
      its(:license) { should eql('Apache 2.0') }
      its(:description) { should eql('Installs/Configures motherbrain') }
      its(:long_description) { should eql('Installs/Configures motherbrain') }
      its(:version) { subject.to_s.should eql('0.1.0') }
      its(:components) { should be_empty }
      its(:commands) { should be_empty }
      its(:dependencies) { should be_empty }
      its(:bootstrap_routine) { should be_nil }

      context "when a cluster_bootstrap block is present" do
        subject do
          described_class.load(metadata) do
            cluster_bootstrap do
              # block
            end
          end
        end

        it "has a Bootstrap::Routine for the value of bootstrap_routine" do
          subject.bootstrap_routine.should be_a(MB::Bootstrap::Routine)
        end
      end

      context "when the metadata contains invalid values for attributes" do
        let(:metadata) do
          MB::CookbookMetadata.new do
            name 1
          end
        end

        it { -> { plugin }.should raise_error MB::InvalidCookbookMetadata }
      end

      context "when the plugin contains an unknown keyword" do
        subject(:plugin) do
          described_class.load(metadata) do
            unknown_keyword
          end
        end

        it { -> { plugin }.should raise_error MB::PluginSyntaxError }
      end
    end

    describe "#from_path" do
      let(:cb_path) { fixtures_path.join('myface-0.1.0') }

      subject { described_class.from_path(cb_path) }

      it "returns a MB::Plugin from the given directory" do
        subject.should be_a(MB::Plugin)
      end
    end
  end

  describe "#to_s" do
    subject do
      described_class.new(metadata)
    end

    it "returns the name and version of the plugin" do
      subject.to_s.should eql("motherbrain (0.1.0)")
    end
  end

  describe "comparing plugins" do
    let(:one) do
      metadata = MB::CookbookMetadata.new do
        name 'apple'
        version '1.0.0'
      end
      described_class.new(metadata)
    end
    let(:two) do
      metadata = MB::CookbookMetadata.new do
        name 'apple'
        version '2.0.0'
      end
      described_class.new(metadata)
    end
    let(:three) do
      metadata = MB::CookbookMetadata.new do
        name 'cherry'
        version '1.0.0'
      end
      described_class.new(metadata)
    end
    let(:four) do
      metadata = MB::CookbookMetadata.new do
        name 'cherry'
        version '2.0.0'
      end
      described_class.new(metadata)
    end
    let(:five) do
      metadata = MB::CookbookMetadata.new do
        name 'orange'
        version '1.0.0'
      end
      described_class.new(metadata)
    end
    let(:six) do
      metadata = MB::CookbookMetadata.new do
        name 'orange'
        version '2.0.0'
      end
      described_class.new(metadata)
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
