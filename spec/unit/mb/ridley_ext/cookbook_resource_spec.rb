require 'spec_helper'

describe Ridley::CookbookResource do
  let(:client) { double('client') }

  describe "#has_motherbrain_plugin?" do
    context "when a metadata.rb and motherbrain.rb file are present in root_files" do
      subject do
        described_class.new(client,
          root_files: [
            {
              name: "metadata.rb",
              url: "https://s3.amazonaws.com/opscode-platform-production-data/organization-(...)",
              checksum: "967087a09f48f234028d3aa27a094882",
              path: "metadata.rb",
              specificity: "default"
            },
            {
              name: "motherbrain.rb",
              url: "https://s3.amazonaws.com/opscode-platform-production-data/organization-(...)",
              checksum: "d18c630c8a68ffa4852d13214d0525a6",
              path: "motherbrain.rb",
              specificity: "default"
            }
          ]
        )
      end

      it { should have_motherbrain_plugin }
    end

    context "when missing a motherbrain.rb file" do
      subject do
        described_class.new(client,
          root_files: [
            {
              name: "metadata.rb",
              url: "https://s3.amazonaws.com/opscode-platform-production-data/organization-(...)",
              checksum: "967087a09f48f234028d3aa27a094882",
              path: "metadata.rb",
              specificity: "default"
            }
          ]
        )
      end

      it { should_not have_motherbrain_plugin }
    end

    context "when missing a metadata.rb file" do
      subject do
        described_class.new(client,
          root_files: [
            {
              name: "motherbrain.rb",
              url: "https://s3.amazonaws.com/opscode-platform-production-data/organization-(...)",
              checksum: "d18c630c8a68ffa4852d13214d0525a6",
              path: "motherbrain.rb",
              specificity: "default"
            }
          ]
        )
      end

      it { should_not have_motherbrain_plugin }
    end
  end
end
