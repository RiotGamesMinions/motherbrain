require 'spec_helper'

describe MB::Provisioners do
  subject { MB::Provisioners }

  before(:each) do
    @original = MB::Provisioners.all
    MB::Provisioners.clear!
  end

  after(:each) do
    MB::Provisioners.clear!
    @original.each do |k|
      MB::Provisioners.register(k)
    end
  end

  describe "::all" do
    it "returns a set" do
      subject.all.should be_a(Set)
    end
  end

  describe "::register" do
    let(:provisioner_class) do
      Class.new do
        include MB::Provisioner

        @provisioner_id = :hello
      end
    end

    it "adds the given class to the list of registered provisioners" do
      subject.register(provisioner_class)

      subject.all.should have(1).item
    end

    describe "registered class" do
      it "has the correct provisioner_id" do
        subject.register(provisioner_class)

        subject.all.first.provisioner_id.should eql(:hello)
      end
    end

    context "given a class that does not respond to provisioner_id" do
      let(:provisioner_class) { Class.new }

      it "raises an InvalidProvisionerClass exception" do
        expect {
          subject.register(provisioner_class)
        }.to raise_error(MB::InvalidProvisionerClass)
      end
    end

    context "given a class with a nil value for provisioner_id" do
      let(:provisioner_class) do
        Class.new do
          include MB::Provisioner

          @provisioner_id = nil
        end
      end

      it "raises an InvalidProvisionerClass exception" do
        expect {
          subject.register(provisioner_class)
        }.to raise_error(MB::InvalidProvisionerClass)
      end
    end
  end
end
