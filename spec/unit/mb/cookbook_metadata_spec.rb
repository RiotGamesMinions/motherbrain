require 'spec_helper'

describe MotherBrain::CookbookMetadata do
  describe "ClassMethods" do
    subject { described_class }

    describe "#load" do
      it "returns an instance of CookbookMetadata" do
        subject.load().should be_a(MB::CookbookMetadata)
      end

      context "when given a block" do
        subject do
          described_class.load do
            name             "motherbrain"
            maintainer       "Jamie Winsor"
            maintainer_email "jamie@vialstudios.com"
            license          "Apache 2.0"
            description      "Installs/Configures motherbrain"
            long_description "Installs/Configures motherbrain"
            version          "0.1.0"

            %w{ centos }.each do |os|
              supports os
            end

            depends "nginx", "~> 1.0.0"
            depends "artifact", "~> 0.11.5"
          end
        end

        it "sets a String value for 'name'" do
          subject.name.should eql("motherbrain")
        end

        it "sets a String value for 'maintainer'" do
          subject.maintainer.should eql("Jamie Winsor")
        end

        it "sets a String value for 'maintainer_email'" do
          subject.maintainer_email.should eql("jamie@vialstudios.com")
        end

        it "sets a String value for 'license" do
          subject.license.should eql("Apache 2.0")
        end

        it "sets a String value for 'description'" do
          subject.description.should eql("Installs/Configures motherbrain")
        end

        it "sets a String value for 'long_description'" do
          subject.long_description.should eql("Installs/Configures motherbrain")
        end

        it "sets a Solve::Version value for 'version'" do
          subject.version.should be_a(Solve::Version)
          subject.version.to_s.should eql("0.1.0")
        end

        it "doesn't complain when a value for an unknown attribute is set" do
          expect {
            obj = described_class.load do
              unknown_keyword "asdf"
            end
          }.to_not raise_error
        end
      end
    end

    describe "#from_file" do
      let(:path) { fixtures_path.join('cb_metadata.rb') }

      it "returns an instance of CookbookMetadata" do
        subject.from_file(path).should be_a(MB::CookbookMetadata)
      end
    end
  end
end
