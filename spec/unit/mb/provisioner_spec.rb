require 'spec_helper'

describe MB::Provisioner do
  subject { described_class }

  before(:each) do
    @original = described_class.all
    described_class.clear!
  end

  after(:each) do
    described_class.clear!
    @original.each { |k| described_class.register(k) }
  end

  describe "::all" do
    it "returns a set" do
      subject.all.should be_a(Set)
    end
  end

  describe "::register" do
    let(:provisioner_class) do
      Class.new(described_class::Base) do
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
        Class.new(described_class::Base) do
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
        rspec_provisioner = Class.new(described_class::Base) do
          register_provisioner :rspec_provisioner
        end

        expect {
          Class.new(described_class::Base) do
            register_provisioner :rspec_provisioner
          end
        }.to raise_error(MB::ProvisionerRegistrationError)
      end
    end

    context "given the :default option set to true" do
      it "sets the given class as the default class" do
        rspec_provisioner = Class.new(described_class::Base) do
          register_provisioner :rspec_provisioner, default: true
        end

        subject.default.should eql(rspec_provisioner)
      end

      it "raises if there is already a default class" do
        rspec_provisioner = Class.new(described_class::Base) do
          register_provisioner :rspec_provisioner, default: true
        end

        expect {
          Class.new(described_class::Base) do
            register_provisioner :rspec_provisioner_two, default: true
          end
        }.to raise_error(MB::ProvisionerRegistrationError)
      end
    end
  end

  describe "::get" do
    it "returns the provisioner class with the given provisioner_id" do
      rspec_provisioner = Class.new(described_class::Base) do
        register_provisioner :rspec_provisioner
      end

      subject.get(:rspec_provisioner).should eql(rspec_provisioner)
    end
  end

  describe "::default" do
    context "given there is a default provisioner class" do
      it "returns the default provisioner class" do
        rspec_provisioner = Class.new(described_class::Base) do
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

describe MB::Provisioner::Base do
  describe "ClassMethods" do
    subject { described_class }

    describe "::validate_create" do
      it "does not raise an error if the number of nodes in the response matches the expected in manifest" do
        manifest = MB::Provisioner::Manifest.new.from_json(
          {
            node_groups: [
              {
                type: "x1.large",
                count: 2,
                components: ["activemq::master"]
              },
              {
                type: "x1.small",
                count: 1,
                components: ["nginx::server"]
              }
            ]
          }.to_json)

        response = [
          {
            name: "a1.riotgames.com",
            instance_type: "x1.large"
          },
          {
            name: "a2.riotgames.com",
            instance_type: "x1.large"
          },
          {
            name: "a3.riotgames.com",
            instance_type: "x1.small"
          }
        ]

        expect {
          subject.validate_create(response, manifest)
        }.to_not raise_error
      end

      it "raises an error if there are less nodes than the manifest expects" do
        manifest = MB::Provisioner::Manifest.new.from_json({
          node_groups: [
            {
              type: "x1.large",
              count: 2,
              components: ["activemq::master"]
            },
            {
              type: "x1.small",
              components: ["nginx::server"]
            }
          ]
        }.to_json)

        response = [
          {
            name: "a1.riotgames.com",
            instance_type: "x1.large"
          }
        ]

        expect {
          subject.validate_create(response, manifest)
        }.to raise_error(MB::UnexpectedProvisionCount)
      end

      it "raises an error if there are more nodes than the manifest expects" do
        manifest = MB::Provisioner::Manifest.new.from_json({
          node_groups: [
            {
              type: "x1.large",
              components: ["activemq::master"]
            }
          ]
        }.to_json)

        response = [
          {
            name: "a1.riotgames.com",
            instance_type: "x1.large"
          },
          {
            name: "a2.riotgames.com",
            instance_type: "x1.large"
          }
        ]

        expect {
          subject.validate_create(response, manifest)
        }.to raise_error(MB::UnexpectedProvisionCount)
      end
    end
  end

  subject { described_class.new }

  describe "#up" do
    let(:job) { double('job') }
    let(:env_name) { "rpsec" }
    let(:manifest) { double('manifest') }
    let(:plugin) { double('plugin') }

    it "raises an AbstractFunction error" do
      expect { subject.up(job, env_name, manifest, plugin) }.to raise_error(MB::AbstractFunction)
    end
  end

  describe "#down" do
    let(:job) { double('job') }
    let(:env_name) { "rpsec" }

    it "raises an AbstractFunction error" do
      expect { subject.down(job, env_name) }.to raise_error(MB::AbstractFunction)
    end
  end
end
