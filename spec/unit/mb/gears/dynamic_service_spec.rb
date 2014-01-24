require 'spec_helper'

describe MB::Gear::DynamicService do
  let(:dynamic_service) { described_class.new('webapp', 'tomcat') }
  let(:plugin) { double(MB::Plugin, name: "MyPlugin", component: component) }
  let(:environment) { "prod" }
  let(:state) { "start" }
  let(:component) { double(get_service: service, group: group) }
  let(:service) { double(service_group: "default", service_attribute: "foo.bar", service_recipe: "tomcat_stop") }
  let(:group) { double(nodes: nodes) }
  let(:nodes) { [ node1, node2 ] }
  let(:node1) { double(name: nil, reload: nil, set_chef_attribute: nil, save: nil) }
  let(:node2) { double(name: nil, reload: nil, set_chef_attribute: nil, save: nil) }

  describe "ClassMethods" do
    let(:service) { "webapp.tomcat" }

    before do
      dynamic_service.stub(:async_state_change)
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
          expect { change_service_state }.to raise_error(MB::InvalidDynamicService)
        end
      end
    end
  end

  let(:job) { double(alive?: false, report_running: nil, set_status: nil, report_success: nil, ticket: nil) }

  describe "#async_state_change" do
    let(:async_state_change) { dynamic_service.async_state_change(plugin, environment, state, options) }
    let(:node_querier) { double(bulk_chef_run: nil) }
    let(:options) { Hash.new }

    before do
      dynamic_service.stub(:node_querier).and_return(node_querier)
      MotherBrain::Job.stub(:new).and_return(job)
    end

    it "starts a bulk chef run" do
      expect(node_querier).to receive(:bulk_chef_run).with(job, nodes, "tomcat_stop")
      async_state_change
    end

    context "when you attempt to change to an unsupported state" do
      let(:state) { "foobar" }
      let(:log) { double( info: nil) }

      before do
        MB::Logging.stub(:logger).and_return(log)
      end

      it "logs a warning" do
        expect(log).to receive(:warn)
        async_state_change
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
        async_state_change
      end
    end
  end

  let(:attribute_key) { "foo.bar" }
  let(:state) { "start" }

  describe "#set_environment_attribute" do
    let(:chef_connection) { double( environment: chef_environment_resource ) }
    let(:chef_environment_resource) { double(find: chef_environment_object) }
    let(:chef_environment_object) { double(set_override_attribute: nil, save: nil) }

    before do
      dynamic_service.stub(:chef_connection).and_return(chef_connection)
    end

    let(:set_environment_attribute) { dynamic_service.set_environment_attribute(job, environment, attribute_key, state) }

    it "sets a chef attribute on the environment" do
      expect(chef_environment_object).to receive(:set_override_attribute).with('foo.bar', 'start')
      expect(chef_environment_object).to receive(:save)
      set_environment_attribute
    end
  end

  describe "#set_node_attributes" do
    let(:set_node_attribute) { dynamic_service.set_node_attributes(job, nodes, attribute_key, state) }

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
