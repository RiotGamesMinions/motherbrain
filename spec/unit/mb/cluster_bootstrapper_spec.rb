require 'spec_helper'

describe MB::ClusterBootstrapper do
  let(:plugin) { MB::Plugin.new(@context) }

  let(:activemq) { MB::Component.new('activemq', @context) }
  let(:mysql) { MB::Component.new('mysql', @context) }
  let(:nginx) { MB::Component.new('nginx', @context) }

  let(:amq_master) do
    double('amq_master',
      name: 'master',
      nodes: [
        double('one', public_hostname: "33.33.33.10"),
        double('two', public_hostname: "33.33.33.11")
      ],
      component: activemq
    )
  end

  let(:amq_slave) do
    double('amq_slave',
      name: 'slave',
      nodes: [],
      component: activemq
    )
  end

  let(:mysql_master) { double('mysql_master', name: 'master', component: mysql) }
  let(:mysql_slave) { double('mysql_slave', name: 'slave', component: mysql) }
  let(:nginx_master) { double('nginx_master', name: 'master', component: nginx) }

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
          amq_master
        ]
      end

      it "returns a Hash" do
        subject.manifest_reduce(manifest, boot_groups).should be_a(Hash)
      end

      it "returns only the key value pairs matched by the given groups" do
        manifest.delete("nginx::master")
        groups = [
          amq_master,
          amq_slave,
          nginx_master
        ]
        reduced = subject.manifest_reduce(manifest, groups)

        reduced.should have(2).items
        reduced.should_not have_key("nginx")
      end
      
      it "accepts a single group instead of an array of groups" do
        subject.manifest_reduce(manifest, amq_master).should have(1).item
      end
    end

    describe "::validate_manifest" do
      let(:manifest) do
        {
          "activemq::master" => [
            "amq1.riotgames.com"
          ],
          "nginx::master" => [
            "nginx1.riotgames.com"
          ]
        }
      end

      before(:each) do
        plugin.stub(:has_component?).with("activemq").and_return(true)
        plugin.stub(:has_component?).with("nginx").and_return(true)
        activemq.stub(:has_group?).with("master").and_return(true)
        nginx.stub(:has_group?).with("master").and_return(true)
      end

      it "returns true if the manifest is valid" do
        subject.validate_manifest(manifest, plugin).should be_true
      end

      context "when manifest contains a component that is not part of the plugin" do
        before(:each) do
          plugin.stub(:has_component?).with("activemq").and_return(false)
          plugin.stub(:has_component?).with("nginx").and_return(false)
        end

        it "raises an InvalidBootstrapManifest error" do
          lambda {
            subject.validate_manifest(manifest, plugin)
          }.should raise_error(MB::InvalidBootstrapManifest)
        end
      end

      context "when manifest contains a group that is not part of a component" do
        before(:each) do
          activemq.stub(:has_group?).with("master").and_return(false)
        end

        it "raises an InvalidBootstrapManifest error" do
          lambda {
            subject.validate_manifest(manifest, plugin)
          }.should raise_error(MB::InvalidBootstrapManifest)
        end
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

      result[0].should have_key("activemq::master")
      result[0].should have_key("activemq::slave")
      result[1].should have_key("nginx::master")
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
