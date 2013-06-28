require 'spec_helper'

describe MB::Bootstrap::Routine do
  describe "ClassMethods" do
    describe "::map_instructions" do
      let(:task_one) { described_class::Task.new("app_server::default") }
      let(:tasks) { [ task_one ] }
      let(:manifest) do
        MB::Bootstrap::Manifest.new(
          node_groups: [
            {
              groups: ["app_server::default"],
              hosts: [
                "euca-10-20-37-171.eucalyptus.cloud.riotgames.com",
                "euca-10-20-37-172.eucalyptus.cloud.riotgames.com"
              ]
            },
            {
              groups: ["database_master::default"],
              hosts: [
                "euca-10-20-37-168.eucalyptus.cloud.riotgames.com"
              ]
            }
          ]
        )
      end

      subject { described_class.map_instructions(tasks, manifest) }

      it "returns a Hash" do
        expect(subject).to be_a(Hash)
      end

      context "given a Task matching a node group in the manifest" do
        let(:task_one) do
          described_class::Task.new("app_server::default",
            run_list: ["recipe[one]", "recipe[two]"],
            chef_attributes: { deep: { nested: { one: "value" } } }
          )
        end

        it "has a key for every host in the matched node group" do
          expect(subject.keys).to have(2).items
        end

        it "each item has a groups key containing an array with an entry for each matching node group" do
          subject.each do |host, info|
            expect(info[:groups]).to have(1).item
            expect(info[:groups]).to include(task_one.group_name)
          end
        end

        it "each item has an options key with a run_list matching the Task's run_list" do
          subject.each do |host, info|
            expect(info[:options][:run_list]).to eql(task_one.run_list)
          end
        end

        it "each item has an options key with a chef_attributes matching the Task's chef_attributes" do
          subject.each do |host, info|
            expect(info[:options][:chef_attributes]).to eql(Hashie::Mash.new(task_one.chef_attributes))
          end
        end

        it "has a Hashie::Mash value for options[:chef_attributes]" do
          subject.each do |host, info|
            expect(info[:options][:chef_attributes]).to be_a(Hashie::Mash)
          end
        end
      end

      context "given two Tasks matching the same node group in the manifest" do
        let(:task_one) do
          described_class::Task.new("app_server::default",
            run_list: ["recipe[one]", "recipe[two]"],
            chef_attributes: { deep: { nested: { one: "value" } } }
          )
        end

        let(:task_two) do
          described_class::Task.new("database_master::default",
            run_list: ["recipe[one]", "recipe[three]"],
            chef_attributes: { deep: { nested: { two: "value" } } }
          )
        end

        let(:manifest) do
          MB::Bootstrap::Manifest.new(
            node_groups: [
              {
                groups: ["app_server::default", "database_master::default"],
                hosts: [
                  "euca-10-20-37-171.eucalyptus.cloud.riotgames.com",
                  "euca-10-20-37-172.eucalyptus.cloud.riotgames.com"
                ]
              }
            ]
          )
        end

        let(:tasks) { [ task_one, task_two ] }

        it "has a key for every host in the matched node group" do
          expect(subject.keys).to have(2).items
        end

        it "each item has a groups key containing an array with an entry for each matching node group" do
          subject.each do |host, info|
            expect(info[:groups]).to have(2).item
            expect(info[:groups]).to include(task_one.group_name)
            expect(info[:groups]).to include(task_two.group_name)
          end
        end

        it "each item has an options key with a run_list including each Task's run_list with no duplicates" do
          subject.each do |host, info|
            expect(info[:options][:run_list]).to include(*task_one.run_list)
            expect(info[:options][:run_list]).to include(*task_two.run_list)
            expect(info[:options][:run_list]).to have(3).items
          end
        end

        it "each item has an options key with a chef_attributes including each Task's chef_attributes" do
          new_attributes = task_one.chef_attributes.deep_merge(task_two.chef_attributes)

          subject.each do |host, info|
            expect(info[:options][:chef_attributes]).to eql(Hashie::Mash.new(new_attributes))
          end
        end
      end

      context "given two Tasks matching different node groups in the manifest" do
        let(:task_one) { described_class::Task.new("app_server::default") }
        let(:task_two) { described_class::Task.new("database_master::default") }
        let(:manifest) do
          MB::Bootstrap::Manifest.new(
            node_groups: [
              {
                groups: ["app_server::default"],
                hosts: [
                  "euca-10-20-37-171.eucalyptus.cloud.riotgames.com",
                  "euca-10-20-37-172.eucalyptus.cloud.riotgames.com"
                ]
              },
              {
                groups: ["database_master::default"],
                hosts: [
                  "euca-10-20-37-168.eucalyptus.cloud.riotgames.com"
                ]
              }
            ]
          )
        end
        let(:tasks) { [ task_one, task_two ] }

        it "has a key for every host in the matched node group" do
          expect(subject.keys).to have(3).items
        end

        it "each item has a groups key containing an array with an entry for each matching node group" do
          subject.each do |host, info|
            expect(info[:groups]).to have(1).item
          end
        end
      end

      context "given a Task that matches no node groups in the manifest" do
        let(:task_one) { described_class::Task.new("database_slave::default") }
        let(:tasks) { [ task_one ] }

        it "returns an empty Hash" do
          expect(subject).to be_empty
        end
      end

      context "given an empty array of tasks" do
        let(:tasks) { Array.new }

        it "returns an empty Hash" do
          expect(subject).to be_empty
        end
      end

      context "given an empty manifest" do
        let(:manifest) { MB::Bootstrap::Manifest.new }

        it "returns an empty Hash" do
          expect(subject).to be_empty
        end
      end
    end
  end

  let(:plugin) do
    metadata = MB::CookbookMetadata.new do
      name "motherbrain"
      version "0.1.0"
    end

    MB::Plugin.new(metadata)
  end

  let(:activemq) { MB::Component.new('activemq', plugin) }
  let(:mysql) { MB::Component.new('mysql', plugin) }
  let(:nginx) { MB::Component.new('nginx', plugin) }

  let(:amq_master) { MB::Group.new('master') }
  let(:amq_slave) { MB::Group.new('slave') }
  let(:mysql_master) { MB::Group.new('master') }
  let(:mysql_slave) { MB::Group.new('slave') }
  let(:nginx_master) { MB::Group.new('master') }

  before(:each) do
    plugin.stub(:components).and_return([activemq, mysql, nginx])
    activemq.stub(:groups).and_return([amq_master, amq_slave])
    mysql.stub(:groups).and_return([mysql_master, mysql_slave])
    nginx.stub(:groups).and_return([nginx_master])
  end

  describe "DSL evaluation" do
    subject do
      described_class.new(plugin) do
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
      subject.task_queue.should have(3).items
    end

    context "each entry" do
      it "is in FIFO order" do
        expect(subject.task_queue[0]).to be_a(Array)
        expect(subject.task_queue[0][0].group_name).to eql("activemq::master")
        expect(subject.task_queue[0][1].group_name).to eql("activemq::slave")
        expect(subject.task_queue[1]).to be_a(Array)
        expect(subject.task_queue[1][0].group_name).to eql("mysql::master")
        expect(subject.task_queue[1][1].group_name).to eql("mysql::slave")
        expect(subject.task_queue[2].group_name).to eql("nginx::master")
      end
    end
  end

  let(:manifest) {
    {
      node_groups: [
        {
          groups: ["activemq::master"],
          hosts: ["amq1.riotgames.com", "amq2.riotgames.com"]
        },
        {
          groups: ["activemq::slave"],
          hosts: ["amqs1.riotgames.com", "amqs2.riotgames.com"]
        },
        {
          groups: ["nginx::master"],
          hosts: ["nginx1.riotgames.com"]
        }
      ]
    }
  }

  subject { described_class.new(plugin) }

  describe "#task_queue" do
    it "returns an array" do
      subject.task_queue.should be_a(Array)
    end

    context "given a routine with async tasks" do
      subject do
        described_class.new(plugin) do
          async do
            bootstrap("activemq::master")
            bootstrap("activemq::slave")
          end
        end
      end

      it "returns an array of arrays of bootstrap routine tasks" do
        subject.task_queue.should have(1).item
        subject.task_queue[0].should have(2).items
        subject.task_queue[0].should each be_a(MB::Bootstrap::Routine::Task)
      end
    end

    context "given a routine with syncronous tasks" do
      subject do
        described_class.new(plugin) do
          bootstrap("activemq::master")
          bootstrap("activemq::slave")
        end
      end

      it "returns an array of bootstrap routine tasks" do
        subject.task_queue.should have(2).items
        subject.task_queue.should each be_a(MB::Bootstrap::Routine::Task)
      end
    end
  end

  describe "#has_task?" do
    subject do
      described_class.new(plugin) do
        bootstrap("activemq::master")
      end
    end

    it "returns true if a bootstrap routine task with the matching ID is present" do
      expect(subject).to have_task("activemq::master")
    end

    it "returns nil if a task with a matching ID is not present" do
      expect(subject).to_not have_task("not::defined")
    end

    context "given a routine with async tasks" do
      subject do
        described_class.new(plugin) do
          async do
            bootstrap("activemq::master")
            bootstrap("activemq::slave")
          end
          bootstrap("nginx::master")
        end
      end

      it "has the nested async tasks and the top level tasks" do
        subject.should have_task("activemq::master")
        subject.should have_task("activemq::slave")
        subject.should have_task("nginx::master")
      end
    end
  end
end

describe MB::Bootstrap::Routine::Task do
  describe "::from_group_path" do
    let(:plugin) do
      metadata = MB::CookbookMetadata.new do
        name "motherbrain"
        version "0.1.0"
      end

      MB::Plugin.new(metadata)
    end

    let(:activemq) { MB::Component.new('activemq', plugin) }
    let(:amq_master) { MB::Group.new('master') }
    let(:group_path) { "activemq::master" }

    before(:each) do
      plugin.stub(:components).and_return([activemq])
      activemq.stub(:groups).and_return([amq_master])
    end

    subject { described_class.from_group_path(plugin, group_path) }

    context "given an invalid string" do
      let(:group_path) { :one_two }

      it "raises a PluginSyntaxError" do
        expect { subject }.to raise_error(MB::PluginSyntaxError)
      end
    end

    context "when the given plugin does not contain the component in the given name" do
      let(:group_path) { "something::master" }

      it "raises a PluginSyntaxError" do
        expect { subject }.to raise_error(MB::PluginSyntaxError)
      end
    end

    context "when the given plugin does not contain the group in the given name" do
      let(:group_path) { "activemq::slave" }

      it "raises a PluginSyntaxError" do
        expect { subject }.to raise_error(MB::PluginSyntaxError)
      end
    end
  end
end
