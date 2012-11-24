require 'spec_helper'

describe MB::Bootstrap::Routine do
  let(:plugin) { MB::Plugin.new(@context) }

  let(:activemq) { MB::Component.new('activemq', @context) }
  let(:mysql) { MB::Component.new('mysql', @context) }
  let(:nginx) { MB::Component.new('nginx', @context) }

  let(:amq_master) { MB::Group.new('master', @context) }
  let(:amq_slave) { MB::Group.new('slave', @context) }
  let(:mysql_master) { MB::Group.new('master', @context) }
  let(:mysql_slave) { MB::Group.new('slave', @context) }
  let(:nginx_master) { MB::Group.new('master', @context) }

  before(:each) do
    plugin.stub(:components).and_return([activemq, mysql, nginx])
    activemq.stub(:groups).and_return([amq_master, amq_slave])
    mysql.stub(:groups).and_return([mysql_master, mysql_slave])
    nginx.stub(:groups).and_return([nginx_master])
  end

  describe "DSL evaluation" do
    subject do
      described_class.new(@context, plugin) do
        async do
          bootstrap("activemq::master")
          bootstrap("activemq::slave")
        end

        async do
          bootstrap("mysql::master")
          bootstrap("mysql::slave")
        end

        bootstrap("nginx::master")
      end
    end

    it "has an entry for each bootstrap or async function call" do
      subject.boot_queue.should have(3).items
    end

    context "each entry" do
      it "is in FIFO order" do
        subject.boot_queue[0].should be_a(Array)
        subject.boot_queue[0][0].group.should eql(amq_master)
        subject.boot_queue[0][0].id.should eql("activemq::master")
        subject.boot_queue[0][1].group.should eql(amq_slave)
        subject.boot_queue[0][1].id.should eql("activemq::slave")
        subject.boot_queue[1].should be_a(Array)
        subject.boot_queue[1][0].group.should eql(mysql_master)
        subject.boot_queue[1][0].id.should eql("mysql::master")
        subject.boot_queue[1][1].group.should eql(mysql_slave)
        subject.boot_queue[1][1].id.should eql("mysql::slave")
        subject.boot_queue[2].group.should eql(nginx_master)
        subject.boot_queue[2].id.should eql("nginx::master")
      end
    end
  end

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

  describe "ClassMethods" do
    subject { described_class }

    describe "::manifest_reduce" do
      let(:boot_groups) do
        [
          double('boot_task_one', id: 'activemq::master', group: amq_master)
        ]
      end

      it "returns a Hash" do
        subject.manifest_reduce(manifest, boot_groups).should be_a(Hash)
      end

      it "contains only key/values where keys matched the id's of the given boot_task(s)" do
        manifest.delete("nginx::master")
        boot_tasks = [
          double('bt_1', id: 'activemq::master', group: amq_master),
          double('bt_2', id: 'activemq::slave', group: amq_slave),
          double('bt_3', id: 'nginx::master', group: nginx_master)
        ]
        reduced = subject.manifest_reduce(manifest, boot_tasks)

        reduced.should have(2).items
        reduced.should_not have_key("nginx::master")
      end
      
      it "accepts a single boot task instead of an array of boot tasks" do
        boot_task = double('bt_1', id: 'activemq::master', group: amq_master)

        subject.manifest_reduce(manifest, boot_task).should have(1).item
      end
    end
  end

  let(:bootstrap_options) do
    {
      server_url: "https://api.opscode.com/organizations/vialstudios",
      ssh_user: "reset",
      ssh_keys: fixtures_path.join("fake_id_rsa").to_s,
      validator_path: fixtures_path.join("fake_key.pem").to_s
    }
  end

  subject { described_class.new(@context, plugin) }

  describe "#run" do
    let(:boot_queue) do
      [
        [
          double('bt_1', id: 'activemq::master', group: amq_master),
          double('bt_2', id: 'activemq::slave', group: amq_slave)
        ],
        double('bt_3', id: 'nginx::master', group: nginx_master)
      ]
    end

    before(:each) do
      subject.stub(:boot_queue).and_return(boot_queue)
    end

    it "returns an array of hashes" do
      result = subject.run(manifest, bootstrap_options)

      result.should be_a(Array)
      result.should each be_a(Hash)
    end

    it "contains an item for every item in the boot_queue" do
      subject.run(manifest, bootstrap_options).should have(2).items
    end

    it "has a hash with a key for each node group of each boot_queue item" do
      result = subject.run(manifest, bootstrap_options)

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
      result = subject.concurrent_bootstrap(manifest, options)

      result.should have(2).items
      result.should have_key("activemq::master")
      result.should have_key("nginx::master")
    end

    it "has a Ridley::SSH::ResponseSet for each value" do
      result = subject.concurrent_bootstrap(manifest, options)

      result["activemq::master"].should be_a(Ridley::SSH::ResponseSet)
      result["nginx::master"].should be_a(Ridley::SSH::ResponseSet)
    end
  end
end
