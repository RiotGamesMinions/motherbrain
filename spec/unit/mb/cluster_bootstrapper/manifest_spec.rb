require 'spec_helper'

describe MB::ClusterBootstrapper::Manifest do
  subject { described_class }

  let(:provisioner_manifest) do
    {
      "m1.large" => {
        "activemq::master" => 2
      },
      "m1.small" => {
        "activemq::slave" => 1
      }
    }
  end

  let(:response) do
    [
      {
        instance_type: "m1.large",
        public_hostname: "euca-10-20-37-171.eucalyptus.cloud.riotgames.com"
      },
      {
        instance_type: "m1.large",
        public_hostname: "euca-10-20-37-172.eucalyptus.cloud.riotgames.com"
      },
      {
        instance_type: "m1.small",
        public_hostname: "euca-10-20-37-169.eucalyptus.cloud.riotgames.com"
      }
    ]
  end

  describe "::from_provisioner" do
    before(:each) do
      @result = subject.from_provisioner(response, provisioner_manifest)
    end

    it "returns a ClusterBootstrapper::Manifest" do
      @result.should be_a(MB::ClusterBootstrapper::Manifest)
    end

    it "has a key for each node type from the provisioner manifest" do
      @result.should have(2).items
      @result.should have_key("activemq::master")
      @result.should have_key("activemq::slave")      
    end

    it "has a node item for each expected node from provisioner manifest" do
      @result["activemq::master"].should have(2).items
      @result["activemq::slave"].should have(1).items
    end
  end
end
