require 'spec_helper'

describe MB::ClusterBootstrapper do
  let(:amq_master) do
    master = double('amq_master', name: 'activemq_master')
    master.stub(:nodes).and_return([
      double('one', public_hostname: "33.33.33.10"),
      double('two', public_hostname: "33.33.33.11")
    ])
    master
  end

  let(:amq_slave) do
    slave = double('amq_slave', name: 'activemq_slave')
    slave.stub(:nodes).and_return([])
    slave
  end

  let(:mysql_master) { double('mysql_master') }
  let(:mysql_slave) { double('mysql_slave') }
  let(:nginx_master) { double('nginx_master', name: 'nginx_master') }

  let(:activemq) do
    activemq = double('activemq')
    activemq.stub(:group!).with("master").and_return(amq_master)
    activemq.stub(:group!).with("slave").and_return(amq_slave)
    activemq
  end

  let(:mysql) do
    mysql = double('mysql')
    mysql.stub(:group!).with("master").and_return(mysql_master)
    mysql.stub(:group!).with("slave").and_return(mysql_slave)
    mysql
  end

  let(:nginx) do
    nginx = double('nginx')
    nginx.stub(:group!).with("master").and_return(nginx_master)
    nginx
  end

  let(:plugin) do
    plugin = double('plugin')
    plugin.stub(:component!).with("activemq").and_return(activemq)
    plugin.stub(:component!).with("mysql").and_return(mysql)
    plugin.stub(:component!).with("nginx").and_return(nginx)
    plugin
  end

  describe "DSL evaluation" do
    subject do
      described_class.new(@context, plugin) do
        async do
          bootstrap("activemq", "master")
          bootstrap("activemq", "slave")
        end

        async do
          bootstrap("mysql", "master")
          bootstrap("mysql", "slave")
        end

        bootstrap("nginx", "master")
      end
    end

    it "has an entry for each bootstrap or async function call" do
      subject.boot_queue.should have(3).items
    end

    it "has a group in the proper order for each bootstrap function call" do
      subject.boot_queue[2].should eql(nginx_master)
    end

    it "has an array of groups in the proper order for each async function call" do
      subject.boot_queue[0].should be_a(Array)
      subject.boot_queue[0][0].should eql(amq_master)
      subject.boot_queue[0][1].should eql(amq_slave)
      subject.boot_queue[1].should be_a(Array)
      subject.boot_queue[1][0].should eql(mysql_master)
      subject.boot_queue[1][1].should eql(mysql_slave)
    end
  end

  let(:manifest) do
    {
      "activemq_master" => [
        "amq1.riotgames.com",
        "amq2.riotgames.com"
      ],
      "activemq_slave" => [
        "amqs1.riotgames.com",
        "amqs2.riotgames.com"
      ],
      "nginx_master" => [
        "nginx1.riotgames.com"
      ]
    }
  end

  describe "ClassMethods" do
    subject { described_class }

    describe "::manifest_reduce" do
      let(:boot_groups) do
        [
          amq_master
        ]
      end

      it "returns a Hash" do
        subject.manifest_reduce(manifest, boot_groups).should be_a(Hash)
      end

      it "returns only the key value pairs matched by the given groups" do
        manifest.delete("nginx_master")
        groups = [
          amq_master,
          amq_slave,
          nginx_master
        ]
        reduced = subject.manifest_reduce(manifest, groups)

        reduced.should have(2).items
        reduced.should_not have_key("nginx_master")
      end
      
      it "accepts a single group instead of an array of groups" do
        subject.manifest_reduce(manifest, amq_master).should have(1).item
      end
    end
  end

  let(:bootstrap_options) do
    {
      ssh_user: "reset",
      ssh_keys: "/Users/reset/.ssh/id_rsa",
      validator_path: "/Users/reset/.chef/riot-validator.pem"
    }
  end

  subject { described_class.new(@context, plugin) }

  describe "#run" do
    let(:boot_queue) do
      [
        [
          amq_master,
          amq_slave
        ],
        nginx_master
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

      result[0].should have_key("activemq_master")
      result[0].should have_key("activemq_slave")
      result[1].should have_key("nginx_master")
    end
  end

  describe "#concurrent_bootstrap" do
    let(:manifest) do
      {
        "activemq_master" => [
          "amq1.riotgames.com",
          "amq2.riotgames.com"
        ],
        "nginx_master" => [
          "nginx1.riotgames.com"
        ]
      }
    end

    let(:options) do
      {
        ssh_user: "reset",
        ssh_password: "fakepass",
        validator_path: fixtures_path.join("fake_key.pem").to_s
      }
    end

    it "returns a Hash containing a key for each group in the manifest" do
      result = subject.concurrent_bootstrap(manifest, options)

      result.should have(2).items
      result.should have_key("activemq_master")
      result.should have_key("nginx_master")
    end

    it "has a Ridley::SSH::ResponseSet for each value" do
      result = subject.concurrent_bootstrap(manifest, options)

      result["activemq_master"].should be_a(Ridley::SSH::ResponseSet)
      result["nginx_master"].should be_a(Ridley::SSH::ResponseSet)
    end
  end
end
