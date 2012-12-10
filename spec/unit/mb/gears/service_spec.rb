require 'spec_helper'

describe MB::Gear::Service do
  let(:component) { double('component', name: 'test-component') }

  describe "Class" do
    subject { MB::Gear::Service }

    it "is registered with MB::Gear" do
      MB::Gear.all.should include(subject)
    end

    it "has the inferred keyword ':service' from it's Class name" do
      subject.keyword.should eql(:service)
    end

    describe "::new" do
      it "sets the given name attribute" do
        obj = subject.new(@context, component, "activemq") do
          # block
        end

        obj.name.should eql("activemq")
      end
    end
  end

  subject do
    MB::Gear::Service.new("service", @context, component) do
      # block
    end
  end

  describe "#actions" do
    subject do
      MB::Gear::Service.new("service", @context, component) do
        action :start do
          node_attribute("key.one", true)
        end

        action :stop do
          # block
        end
      end
    end

    it "returns a Set of Gear::Action::Service objects for each defined action" do
      subject.actions.should be_a(Set)
      subject.actions.should have(2).items
      subject.actions.should each be_a(MB::Gear::Service::Action)
    end
  end

  describe "#action" do
    subject do
      MB::Gear::Service.new("activemq", @context, component) do
        action :start do
          node_attribute("key.one", true)
        end
      end
    end

    it "returns a Gear::Service::Action" do
      subject.action(:start).should be_a(MB::Gear::Service::Action)
    end

    context "given an action that does not exist" do
      it "raises an ActionNotFound error" do
        lambda {
          subject.action(:stop)
        }.should raise_error(MB::ActionNotFound)
      end
    end
  end

  describe "#add_action" do
    let(:action_1) { double('action_1', name: "start") }
    let(:action_2) { double('action_2', name: "stop") }

    it "adds the given action to the set of actions" do
      subject.add_action(action_1)

      subject.actions.should have(1).item
      subject.action("start").should eql(action_1)
    end

    context "when an action of the given name has already been defined" do
      it "raises a DuplicateAction error" do
        lambda {
          subject.add_action(action_1)
          subject.add_action(action_1)
        }.should raise_error(MB::DuplicateAction)
      end
    end
  end

  describe MB::Gear::Service::Action do
    let(:klass) { MB::Gear::Service::Action }

    let(:node_1) { double('node_1', name: 'reset', public_hostname: 'reset.riotgames.com') }
    let(:node_2) { double('node_2', name: 'jwinsor', public_hostname: 'jwinsor.riotgames.com') }
    let(:node_3) { double('node_3', name: 'jwinsor-2', public_hostname: 'jwinsor-2.riotgames.com') }
    let(:nodes) { [ node_1, node_2, node_3 ] }

    describe "#run" do
      subject do
        klass.new(@context, :start, component) do
          # block
        end
      end

      let(:key) { "some.attr" }
      let(:value) { "val" }
      let(:chef_success) { double('success-response', error?: false) }

      it "runs Chef on every node" do        
        MB::Application.node_querier.should_receive(:chef_run).with(node_1.public_hostname).
          and_return(chef_success)
        MB::Application.node_querier.should_receive(:chef_run).with(node_2.public_hostname).
          and_return(chef_success)
        MB::Application.node_querier.should_receive(:chef_run).with(node_3.public_hostname).
          and_return(chef_success)

        subject.run(nodes)
      end

      context "when an environment attribute is specified" do
        let(:key) { "some.attr" }
        let(:value) { "val" }

        subject do
          klass.new(@context, :start, component) do
            environment_attribute("some.attr", "val")
          end
        end

        it "sets an environment attribute" do
          subject.send(:runner).should_receive(:set_environment_attribute).with(key, value, toggle: false)

          subject.run([])
        end

        context "when toggle: true" do
          subject do
            klass.new(@context, :start, component) do
              environment_attribute("some.attr", "val", toggle: true)
            end
          end

          it "sets an environment attribute and then sets it back" do
            subject.send(:runner).should_receive(:set_environment_attribute).with(key, value, toggle: true)

            subject.run([])
          end
        end
      end

      context "when a node attribute is specified" do
        subject do
          klass.new(@context, :start, component) do
            node_attribute("some.attr", "val", toggle: true)
          end
        end

        it "sets a node attribute on each node" do
          success = double('success-response', error?: false)
          MB::Application.node_querier.should_receive(:chef_run).exactly(3).times.and_return(chef_success)
          subject.send(:runner).should_receive(:set_node_attribute).with(node_1, key, value, toggle: true)
          subject.send(:runner).should_receive(:set_node_attribute).with(node_2, key, value, toggle: true)
          subject.send(:runner).should_receive(:set_node_attribute).with(node_3, key, value, toggle: true)

          subject.run(nodes)
        end
      end
    end
  end
end
