require 'spec_helper'

describe MB::Provisioner do
  describe "ClassMethods" do
    subject do
      Class.new do
        include MB::Provisioner
      end
    end

    describe "::validate_create" do
      it "does not raise an error if the number of nodes in the response matches the expected in manifest" do
        manifest = MB::Provisioner::Manifest.new.from_json({
          "x1.large" => {
            "activemq::master" => 2,
          },
          "x1.small" => {
            "nginx::server" => 1
          }
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
          "x1.large" => {
            "activemq::master" => 2,
          },
          "x1.small" => {
            "nginx::server" => 1
          }
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
          "x1.large" => {
            "activemq::master" => 1
          }
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
