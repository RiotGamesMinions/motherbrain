require 'spec_helper'

describe MotherBrain do
  subject { MotherBrain }

  describe "::ui" do
    it "returns an instance of Thor::Shell::Color" do
      subject.ui.should be_a(Thor::Shell::Color)
    end
  end

  describe "::root" do
    it "returns a pathname" do
      subject.root.should be_a(Pathname)
    end
  end
end
