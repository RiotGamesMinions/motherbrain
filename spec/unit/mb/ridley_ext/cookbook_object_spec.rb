require 'spec_helper'

describe Ridley::CookbookObject do
  let(:client) { double('client') }

  describe "#has_motherbrain_plugin?" do
    context "when a metadata.rb, metadata.json, and motherbrain.rb file are present in root_files" do
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

    context "when a motherbrain.rb is present" do
      let(:root_files) do
        [
          {
            name: "motherbrain.rb",
            url: "https://s3.amazonaws.com/opscode-platform-production-data/organization-(...)",
            checksum: "d18c630c8a68ffa4852d13214d0525a6",
            path: "motherbrain.rb",
            specificity: "default"
          }
        ]
      end

      subject { described_class.new(client, root_files: root_files) }

      context "when a metadata.rb is present in the root_files" do
        before do
          root_files << {
            name: "metadata.rb",
            url: "https://s3.amazonaws.com/opscode-platform-production-data/organization-(...)",
            checksum: "967087a09f48f234028d3aa27a094882",
            path: "metadata.rb",
            specificity: "default"
          }
        end

        it { should have_motherbrain_plugin }
      end

      context "when a metadata.json is present in the root_files" do
        before do
          root_files << {
            name: "metadata.json",
            url: "https://s3.amazonaws.com/opscode-platform-production-data/organization-(...)",
            checksum: "44ca6f96d3f0a7299cfff2f69295bc55",
            path: "metadata.json",
            specificity: "default"
          }
        end

        it { should have_motherbrain_plugin }
      end

      context "when there is no metadata.rb or metadata.json in the root_files" do
        it { should_not have_motherbrain_plugin }
      end
    end

    context "when missing a motherbrain.rb file" do
      let(:root_files) do
        [
          {
            name: "metadata.rb",
            url: "https://s3.amazonaws.com/opscode-platform-production-data/organization-(...)",
            checksum: "967087a09f48f234028d3aa27a094882",
            path: "metadata.rb",
            specificity: "default"
          },
          {
            name: "metadata.json",
            url: "https://s3.amazonaws.com/opscode-platform-production-data/organization-(...)",
            checksum: "44ca6f96d3f0a7299cfff2f69295bc55",
            path: "metadata.json",
            specificity: "default"
          }
        ]
      end

      subject { described_class.new(client, root_files: root_files) }

      it { should_not have_motherbrain_plugin }
    end
  end
end
