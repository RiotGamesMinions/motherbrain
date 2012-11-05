require 'spec_helper'

describe MotherBrain::Gear do
  before(:each) do
    @original = MotherBrain::Gear.all
    MotherBrain::Gear.clear!
  end

  after(:each) do
    MotherBrain::Gear.clear!
    @original.each do |k|
      MotherBrain::Gear.register(k)
    end
  end

  describe "ClassMethods" do
    subject { MotherBrain::Gear }

    describe "::all" do
      it "returns a Set" do
        subject.all.should be_a(Set)
      end

      context "when no Classes include MotherBrain::Gear" do
        before(:each) { subject.clear! }

        it "returns an empty Set" do
          subject.all.should be_empty
        end
      end

      context "when a Class includes MotherBrain::Gear" do
        before(:each) do
          @descendant = Class.new do
            include MotherBrain::Gear
            register_gear :fake_one
          end

          @descendant_2 = Class.new do
            include MotherBrain::Gear
            register_gear :fake_two
          end
        end

        it "returns an array with the descendant Class" do
          subject.all.should have(2).item
          subject.all.should include(@descendant)
          subject.all.should include(@descendant_2)
        end
      end

      context "when a Class includes MotherBrain::Gear multiple times" do
        before(:each) do
          @descendant = Class.new do
            include MotherBrain::Gear
            include MotherBrain::Gear
            register_gear :fake_gear
          end
        end

        it "does not register multiple times" do
          subject.all.should have(1).item
        end
      end
    end

    describe "::clear!" do
      it "sets ::all to an empty Set" do
        subject.clear!

        subject.all.should be_empty
      end
    end

    describe "::find_by_keyword" do
      before(:each) do
        @klass = Class.new do
          include MotherBrain::Gear

          register_gear :fake_gear
        end
      end

      it "returns the class with the registered keyword" do
        subject.find_by_keyword(:fake_gear).should eql(@klass)
      end

      it "returns nil if a class with the given keyword is not registered" do
        subject.find_by_keyword(:not_registered).should be_nil
      end
    end
  end

  describe "::register_gear" do
    it "sets the keyword class attribute" do
      @klass = Class.new do
        include MotherBrain::Gear
        register_gear :racer
      end

      @klass.keyword.should eql(:racer)
    end

    context "when registering a keyword that has already been used" do
      it "raises a DuplicateGearKeyword error" do
        Class.new do
          include MotherBrain::Gear
          register_gear :racer
        end

        lambda {
          Class.new do
            include MotherBrain::Gear
            register_gear :racer
          end
        }.should raise_error(MotherBrain::DuplicateGearKeyword)
      end
    end

    context "when registering a RESERVED_KEYWORD" do
      it "raises a ReservedGearKeyword error" do
        MotherBrain::Gear::RESERVED_KEYWORDS.each do |key|
          lambda {
            Class.new do
              include MotherBrain::Gear
              register_gear key
            end
          }.should raise_error(MotherBrain::ReservedGearKeyword)
        end
      end
    end
  end
end
