require 'spec_helper'

describe MotherBrain::Chef::RunListItem do
  describe "#cookbook_name" do
    context "recipe item" do
      shared_examples "a recipe item" do
        it "should return the cookbook" do
          expect(subject.cookbook_name).to eq("foo")
        end
      end

      context do
        subject { described_class.new("recipe[foo::server]") }
        it_behaves_like "a recipe item"
      end

      context do
        subject { described_class.new("recipe[foo::server@1.1.2]") }
        it_behaves_like "a recipe item"
      end

      context do
        subject { described_class.new("recipe[foo]") }
        it_behaves_like "a recipe item"
      end
    end
    context "role item" do
      subject { described_class.new("role[foo]") }
      it "should return nil" do
        expect(subject.cookbook_name).to be_nil
      end
    end
  end
end
