require 'spec_helper'

describe MB::Gear do
  before(:each) do
    MB::Gear.clear!
  end

  after(:each) do
    MB::Gear.reload!
  end

  describe "::all" do
    it "returns a Set" do
      subject.all.should be_a(Set)
    end

    context "when no Classes include MB::Gear" do
      subject { MB::Gear }
      
      it "returns an empty Set" do
        subject.all.should be_empty
      end
    end

    context "when a Class includes MB::Gear" do
      subject { MB::Gear }

      before(:each) do
        @descendant = Class.new do
          include MB::Gear
        end

        @descendant_2 = Class.new do
          include MB::Gear
        end
      end

      it "returns an array with the descendant Class" do
        subject.all.should have(2).item
        subject.all.should include(@descendant)
        subject.all.should include(@descendant_2)
      end
    end

    context "when a Class includes MB::Gear multiple times" do
      before(:each) do
        @descendant = Class.new do
          include MB::Gear
          include MB::Gear
        end
      end

      it "does not register multiple times" do
        subject.all.should have(1).item
      end
    end
  end

  describe "::clear!" do
    after(:each) { subject.reload! }

    it "sets ::all to an empty Set" do
      subject.clear!

      subject.all.should be_empty
    end
  end

  describe MB::Gear::ClassMethods do
    subject do
      Class.new do
        include MB::Gear
      end
    end

    describe "::set_keyword" do
      it "sets the keyword class attribute" do
        subject.set_keyword "service"

        subject.keyword.should eql(:service)
      end
    end

    describe "::keyword" do
      it "returns a symbol inferred from the class name" do
        subject.keyword.should be_a(Symbol)
      end
    end

    describe "::new" do
      pending
    end
  end
end
