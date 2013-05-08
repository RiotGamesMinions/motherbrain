require 'spec_helper'

describe Enumerable do
  class ObjectClass
    def foo
      :result
    end

    def bar(one, two, three)
      [one, two, three]
    end
  end

  class ActorClass < ObjectClass
    include Celluloid
  end

  let(:actors) { [ActorClass.new, ActorClass.new] }
  let(:objects) { [ObjectClass.new, ObjectClass.new] }
  let(:mixed) { [ActorClass.new, ObjectClass.new] }

  let(:block) { proc { |item| item.foo } }

  let(:array) { actors }

  let(:foo_result) { [:result, :result] }
  let(:bar_result) { [[1, 2, 3], [1, 2, 3]] }

  describe "#concurrent_map" do
    subject { concurrent_map }

    context "when passed a method" do
      let(:concurrent_map) { array.concurrent_map(:foo) }

      context "with actors" do
        let(:array) { actors }

        it { should eq(foo_result) }
      end

      context "with objects" do
        let(:array) { objects }

        it { should eq(foo_result) }
      end

      context "with mixed actors and objects" do
        let(:array) { mixed }

        it { should eq(foo_result) }
      end
    end

    context "when passed a method and arguments" do
      let(:concurrent_map) { array.concurrent_map(:bar, 1, 2, 3) }

      context "with actors" do
        let(:array) { actors }

        it { should eq(bar_result) }
      end

      context "with objects" do
        let(:array) { objects }

        it { should eq(bar_result) }
      end

      context "with mixed actors and objects" do
        let(:array) { mixed }

        it { should eq(bar_result) }
      end
    end

    context "when passed a block" do
      let(:concurrent_map) { array.concurrent_map(&block) }

      context "with actors" do
        let(:array) { actors }

        it { should eq(foo_result) }
      end

      context "with objects" do
        let(:array) { objects }

        it { should eq(foo_result) }
      end

      context "with mixed actors and objects" do
        let(:array) { mixed }

        it { should eq(foo_result) }
      end
    end

    context "with no arguments or block" do
      let(:concurrent_map) { array.concurrent_map }

      it { expect { concurrent_map }.to raise_error(ArgumentError) }
    end
  end
end
