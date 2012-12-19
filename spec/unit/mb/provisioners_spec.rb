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

    context "when a provisioner with the given id has already been registered" do
      it "raises an ProvisionerRegistrationError" do
        rspec_provisioner = Class.new do
          include MB::Provisioner
          register_provisioner :rspec_provisioner
        end

        expect {
          Class.new do
            include MB::Provisioner
            register_provisioner :rspec_provisioner
          end
        }.to raise_error(MB::ProvisionerRegistrationError)
      end
    end

    context "given the :default option set to true" do
      it "sets the given class as the default class" do
        rspec_provisioner = Class.new do
          include MB::Provisioner
          register_provisioner :rspec_provisioner, default: true
        end

        subject.default.should eql(rspec_provisioner)
      end

      it "raises if there is already a default class" do
        rspec_provisioner = Class.new do
          include MB::Provisioner
          register_provisioner :rspec_provisioner, default: true
        end

        expect {
          Class.new do
            include MB::Provisioner
            register_provisioner :rspec_provisioner_two, default: true
          end
        }.to raise_error(MB::ProvisionerRegistrationError)
      end
    end
  end

  describe "::get" do
    it "returns the provisioner class with the given provisioner_id" do
      rspec_provisioner = Class.new do
        include MB::Provisioner
        register_provisioner :rspec_provisioner
      end

      subject.get(:rspec_provisioner).should eql(rspec_provisioner)
    end
  end

  describe "::default" do
    context "given there is a default provisioner class" do
      it "returns the default provisioner class" do
        rspec_provisioner = Class.new do
          include MB::Provisioner
          register_provisioner :rspec_provisioner, default: true
        end

        subject.default.should eql(rspec_provisioner)
      end
    end

    context "when there is no default provisioner class" do
      it "returns nil" do
        subject.default.should be_nil
      end
    end
  end
end
