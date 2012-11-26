require 'spec_helper'

describe MB::Bootstrap::Manager do
  let(:plugin) { MB::Plugin.new(@context) }

  let(:manifest) do
    {
      "activemq::master" => [
        "amq1.riotgames.com",
        "amq2.riotgames.com"
      ],
      "activemq::slave" => [
        "amqs1.riotgames.com",
        "amqs2.riotgames.com"
      ],
      "nginx::master" => [
        "nginx1.riotgames.com"
      ]
    }
  end

  let(:bootstrap_options) do
    {
      server_url: "https://api.opscode.com/organizations/vialstudios",
      ssh_user: "reset",
      ssh_keys: fixtures_path.join("fake_id_rsa").to_s,
      validator_path: fixtures_path.join("fake_key.pem").to_s
    }
  end

  subject { described_class.new }

  describe "#bootstrap" do
    let(:task_queue) do
      [
        [
          double('bt_1', id: 'activemq::master', group: amq_master),
          double('bt_2', id: 'activemq::slave', group: amq_slave)
        ],
        double('bt_3', id: 'nginx::master', group: nginx_master)
      ]
    end

    before(:each) do
      subject.stub(:task_queue).and_return(task_queue)
    end

    it "returns an array of hashes" do
      result = subject.bootstrap(manifest, plugin.bootstrap_routine, bootstrap_options)

      result.should be_a(Array)
      result.should each be_a(Hash)
    end

    it "contains an item for every item in the task_queue" do
      subject.bootstrap(manifest, plugin.bootstrap_routine, bootstrap_options).should have(2).items
    end

    it "has a hash with a key for each node group of each task_queue item" do
      result = subject.bootstrap(manifest, plugin, bootstrap_options)

      result[0].should have_key("activemq::master")
      result[0].should have_key("activemq::slave")
      result[1].should have_key("nginx::master")
    end
  end

  describe "#concurrent_bootstrap" do
    let(:manifest) do
      {
        "activemq::master" => [
          "amq1.riotgames.com",
          "amq2.riotgames.com"
        ],
        "nginx::master" => [
          "nginx1.riotgames.com"
        ]
      }
    end

    let(:options) do
      {
        server_url: "https://api.opscode.com/organizations/vialstudios",
        ssh_user: "reset",
        ssh_password: "fakepass",
        validator_path: fixtures_path.join("fake_key.pem").to_s
      }
    end

    it "returns a Hash containing a key for each group in the manifest" do
      result = subject.concurrent_bootstrap(manifest, plugin, options)

      result.should have(2).items
      result.should have_key("activemq::master")
      result.should have_key("nginx::master")
    end

    it "has a Ridley::SSH::ResponseSet for each value" do
      result = subject.concurrent_bootstrap(manifest, plugin, options)

      result["activemq::master"].should be_a(Ridley::SSH::ResponseSet)
      result["nginx::master"].should be_a(Ridley::SSH::ResponseSet)
    end
  end
end
