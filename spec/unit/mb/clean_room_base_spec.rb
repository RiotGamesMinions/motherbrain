require 'spec_helper'

describe MB::CleanRoomBase do
  let(:context) { double('context') }
  let(:binding) { double('binding') }
  let(:block) { double('block') }

  describe "ClassMethods" do
    subject { MB::CleanRoomBase }

    describe "::bind_attribute" do
      it "creates a function of the given name on the instance of clean room" do
        subject.bind_attribute :name

        subject.new(context, binding) do
          # block
        end.should respond_to(:name)
      end

      it "assigns the value from the generated function to the binding" do
        value = double('value')
        subject.bind_attribute :name

        binding.should_receive(:name=).with(value)

        subject.new(context, binding) do
          # block
        end.name(value)
      end
    end
  end
end
