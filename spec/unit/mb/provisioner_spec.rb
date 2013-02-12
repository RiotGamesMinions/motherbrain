require 'spec_helper'

describe MB::Provisioner do
  describe "ClassMethods" do
    subject {
      Class.new do
        include MB::Provisioner
      end
    }

    describe "::validate_create" do
      it "does not raise an error if the number of nodes in the response matches the expected in manifest" do
        manifest = MB::Provisioner::Manifest.new.from_json(
          {
            nodes: [
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
          nodes: [
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
          nodes: [
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

  subject do
    Class.new do
      include MB::Provisioner
    end.new
  end

  it { subject.should respond_to(:up) }
  it { subject.should respond_to(:down) }
end
