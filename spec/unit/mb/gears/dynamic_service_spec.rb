require 'spec_helper'

describe MB::Gear::DynamicService do
  let(:dynamic_service) { described_class.new('webapp', 'tomcat') }
  let(:plugin) { double(MB::Plugin, name: "MyPlugin", component: component) }
  let(:environment) { "prod" }
  let(:state) { "start" }
  let(:component) { double(get_service: service, group: group) }
  let(:service) { double(service_group: "default", service_attribute: ["foo.bar"], service_recipe: ["tomcat_stop"]) }
  let(:group) { double(nodes: nodes) }
  let(:nodes) { [ node1, node2 ] }
  let(:node1) { double(name: nil, reload: nil, set_chef_attribute: nil, save: nil) }
  let(:node2) { double(name: nil, reload: nil, set_chef_attribute: nil, save: nil) }
  let(:job) { MB::Job.new(:thejob) }
  describe "ClassMethods" do
    let(:service) { "webapp.tomcat" }

    before do
      dynamic_service.stub(:state_change)
      MB::Job.should_receive(:new).and_return(job)
    end

    describe "::change_service_state" do
      let(:change_service_state) { MB::Gear::DynamicService.change_service_state(service, plugin, environment, state) }

      it "splits the service on a period" do
        expect(MB::Gear::DynamicService).to receive(:new).with('webapp', 'tomcat').and_return(dynamic_service)
        change_service_state
      end

      context "when the service is not formatted as 'COMPONENT.SERVICE'" do
        let(:service) { "foo" }

        it "raises an error" do
          job.should_receive(:report_failure).with(kind_of(MB::InvalidDynamicService))
          change_service_state
        end
      end
    end
  end

  let(:job) { double(alive?: false, report_running: nil, set_status: nil, report_success: nil, ticket: nil) }

  describe "#state_change" do
    let(:state_change) { dynamic_service.state_change(job, plugin, environment, state, true, options) }
    let(:node_querier) { double(bulk_chef_run: nil) }
    let(:options) { Hash.new }

    before do
      dynamic_service.stub(:unset_environment_attribute)
      dynamic_service.stub(:set_node_attributes)
      dynamic_service.stub(:node_querier).and_return(node_querier)
      MotherBrain::Job.stub(:new).and_return(job)
    end

    it "starts a bulk chef run" do
      expect(node_querier).to receive(:bulk_chef_run).with(job, nodes, ["tomcat_stop"])
      state_change
    end

    context "when you attempt to change to an unsupported state" do
      let(:state) { "foobar" }
      let(:log) { double( info: nil) }

      before do
        MB::Logging.stub(:logger).and_return(log)
      end

      it "logs a warning" do
        expect(log).to receive(:warn)
        state_change
      end
    end

    context "when the cluster override flag is provided" do
      let(:options) do
        {
          cluster_override: true
        }
      end

      it "sets an attribute on the environment" do
        expect(dynamic_service).to receive(:set_environment_attribute)
        state_change
      end
    end
  end

  describe "#remove_node_state_change" do
    subject { MB::Gear::DynamicService.new(component_name, service_name) }
    let(:service_name) { "foo_service" }
    let(:service) { double(MB::Gear::Service,
                           service_attribute: ["foo.service_attr"],
                           service_recipe: service_recipe) }
    let(:component_name) { "foo_component" }
    let(:plugin) { double(MB::Plugin) }
    let(:component) { double(MB::Component) }
    let(:node_querier) { double(MB::NodeQuerier) }
    let(:node) { double(Ridley::NodeObject) }
    let(:service_recipe) { "recipe[foo::service]" }

    before do
      plugin.stub(:component).with(component_name).and_return(component)
      component.stub(:get_service).with(service_name).and_return(service)
      subject.stub(:node_querier).and_return(node_querier)
      subject.stub(:set_node_attributes).with(job, [node], service.service_attribute, nil)
      node_querier.stub(:bulk_chef_run).with(job, [node], service.service_recipe)
    end
    
    it "should run chef by default" do
      expect(node_querier).to receive(:bulk_chef_run).with(job, [node], service_recipe)
      subject.remove_node_state_change(job, plugin, node)
    end

    it "should not run chef if told not to" do
      expect(node_querier).not_to receive(:bulk_chef_run)
      subject.remove_node_state_change(job, plugin, node, false)
    end

    it "should set the service node attributes to nil" do
      expect(subject).to receive(:set_node_attributes).with(job, [node], service.service_attribute, nil)
      subject.remove_node_state_change(job, plugin, node, false)
    end
  end

  describe "#get_chef_environment" do
    let(:get_chef_environment) { dynamic_service.get_chef_environment(environment) }
    let(:result) { double() }

    before do
      dynamic_service.stub_chain(:chef_connection, :environment, :find).and_return(result)
    end

    it "returns the chef environment object" do
      expect(get_chef_environment).to eql(result)
    end
  end

  let(:attribute_keys) { ["foo.bar"] }
  let(:state) { "start" }
  let(:chef_environment_object) { double(set_override_attribute: nil, delete_override_attribute: nil, save: nil) }

  describe "#set_environment_attribute" do

    before do
      dynamic_service.stub(:get_chef_environment).and_return(chef_environment_object)
    end

    let(:set_environment_attribute) { dynamic_service.set_environment_attribute(job, environment, attribute_keys, state) }

    it "sets a chef attribute on the environment" do
      expect(chef_environment_object).to receive(:set_override_attribute).with('foo.bar', 'start')
      expect(chef_environment_object).to receive(:save)
      set_environment_attribute
    end
  end

  describe "#unset_environment_attribute" do
    let(:unset_environment_attribute) { dynamic_service.unset_environment_attribute(job, environment, attribute_keys) }

    before do
      dynamic_service.stub(:get_chef_environment).and_return(chef_environment_object)
    end

    it "deletes a chef attribute on the environment" do
      expect(chef_environment_object).to receive(:delete_override_attribute).with('foo.bar')
      expect(chef_environment_object).to receive(:save)
      unset_environment_attribute
    end
  end

  describe "#set_node_attributes" do
    let(:set_node_attribute) { dynamic_service.set_node_attributes(job, nodes, attribute_keys, state) }

    it "sets a chef attribute on the node" do
      expect(node1).to receive(:set_chef_attribute).with("foo.bar", "start")
      expect(node2).to receive(:set_chef_attribute).with("foo.bar", "start")
      set_node_attribute
    end

    it "saves the node" do
      expect(node1).to receive(:save)
      expect(node2).to receive(:save)
      set_node_attribute
    end
  end
end
