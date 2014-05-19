require 'spec_helper'

describe MB::NodeQuerier do
  subject { node_querier }

  let(:node_querier) { described_class.new }
  let(:host) { "192.168.1.1" }
  let(:response) { double('response', stderr: nil, stdout: nil, error?: nil) }

  describe "#list" do
    it "returns a list of nodes from the motherbrain's chef connection" do
      nodes = double
      MB::Application.ridley.stub_chain(:node, :all).and_return(nodes)

      subject.list.should eql(nodes)
    end
  end

  describe "#ruby_script" do
    subject(:result) { node_querier.send(:ruby_script, 'node_name', double('host')) }
    before { node_querier.stub_chain(:chef_connection, :node, :ruby_script).and_return(response) }

    context "when the response is a success" do
      before { response.stub(stdout: 'success', error?: false) }

      it "returns the response of the successfully run script" do
        expect(result).to eql('success')
      end
    end

    context "when the response is a failure" do
      before { response.stub(stderr: 'error_message', error?: true) }

      it "raises a RemoteScriptError" do
        expect { result }.to raise_error(MB::RemoteScriptError)
      end
    end
  end

  describe "#bulk_chef_run" do
    let(:job) { double(set_status: nil) }
    let(:node_one) { double(name: "surfing", public_hostname: "surfing.riotgames.com") }
    let(:node_two) { double(name: "football", public_hostname: "football.riotgames.com") }
    let(:response_one) { double(value: double(host: "surfing.riotgames.com")) }
    let(:response_two) { double(value: double(host: "football.riotgames.com")) }

    let(:nodes) { [ node_one, node_two ] }

    let(:bulk_chef_run) { node_querier.bulk_chef_run(job, nodes) }

    before do
      # Stubbing node_querier.future proved to be very difficult
      nodes.stub(:map).and_return([response_one, response_two])
    end

    it "describes the successful nodes" do
      bulk_chef_run
      expect(job).to have_received(:set_status).with(
        "Finished chef client run on 2 node(s) - surfing.riotgames.com, football.riotgames.com")
    end

    context "when nodes fail" do

      before do
        response_one.stub(:value).and_raise(MB::RemoteCommandError.new(nil, "surfing.riotgames.com"))
        response_two.stub(:value).and_raise(MB::RemoteCommandError.new(nil, "football.riotgames.com"))
        node_querier.stub(:abort)
      end

      it "describes the unsuccessful nodes" do
        node_querier.should_receive(:abort).with(
          MB::RemoteCommandError.new("chef client run failed on 2 node(s) - surfing.riotgames.com, football.riotgames.com"))
        bulk_chef_run
      end
    end
  end

  describe "#node_name" do
    subject(:node_name) { node_querier.node_name(host) }

    let(:node) { "my_node" }

    it "calls ruby_script with node_name and returns a response" do
      node_querier.should_receive(:ruby_script).with('node_name', host, {}).and_return(node)
      node_name.should eq(node)
    end

    context "with a remote script error" do
      before do
        node_querier.stub(:ruby_script).and_raise(MB::RemoteScriptError)
      end

      it { should be_nil }
    end
  end

  describe "#chef_run" do
    subject(:result) { node_querier.chef_run(host, options) }
    let(:options) { Hash.new }

    before { node_querier.stub_chain(:chef_connection, :node, :chef_run).and_return(response) }

    context "when the response is a success" do
      before { response.stub(stdout: 'success', error?: false) }

      it "returns the Ridley response" do
        expect(result).to eql(response)
      end
    end

    context "when the response is a failure" do
      before { response.stub(stderr: 'error_message', error?: true) }

      it "raises a RemoteCommandError" do
        expect { result }.to raise_error(MB::RemoteCommandError)
      end
    end

    context "when hostname is nil" do
      let(:host) { nil }

      it "raises a RemoteCommandError" do
        expect { result }.to raise_error(MB::RemoteCommandError)
      end
    end

    context "when hostname is blank" do
      let(:host) { "" }

      it "raises a RemoteCommandError" do
        expect { result }.to raise_error(MB::RemoteCommandError)
      end
    end

    context "when there are override recipes" do
      let(:node_object) { double(reload: nil, automatic_attributes: auto_attr, save: nil) }
      let(:auto_attr) { double(recipes: nil, :recipes= => nil) }
      let(:options) do
        {
          override_recipes: ["default::foo"],
          node_object: node_object
        }
      end

      before do
        node_querier.stub_chain(:chef_connection, :node, :execute_command).and_return(response)
      end

      it "returns the ridley response" do
        expect(result).to eql(response)
      end
    end
  end

  describe "#put_secret" do
    let(:options) { { secret: File.join(fixtures_path, "fake_key.pem") } }
    subject(:result) { node_querier.put_secret(host, options) }

    before { node_querier.stub_chain(:chef_connection, :node, :put_secret).and_return(response) }

    context "when there is no file at the secret path" do
      let(:options) { Hash.new }

      it { should be_nil }
    end

    context "when the response is a success" do
      before { response.stub(stdout: 'success', error?: false) }

      it "returns the Ridley response" do
        expect(result).to eql(response)
      end
    end

    context "when the response is a failure" do
      before { response.stub(stderr: 'error_message', error?: true) }

      it { should be_nil }
    end
  end

  describe "#execute_command" do
    let(:command) { "echo 'hello!'" }
    subject(:result) { node_querier.execute_command(host, command) }
    before { node_querier.stub_chain(:chef_connection, :node, :execute_command).and_return(response) }

    context "when the response is a success" do
      before { response.stub(stdout: 'success', error?: false) }

      it "returns the Ridley response" do
        expect(result).to eql(response)
      end
    end

    context "when the response is a failure" do
      before { response.stub(stderr: 'error_message', error?: true) }

      it "raises a RemoteCommandError" do
        expect { result }.to raise_error(MB::RemoteCommandError)
      end
    end
  end

  describe "#registered?" do
    let(:node_name) { "reset.riotgames.com" }

    it "returns true if the target node is registered with the Chef server" do
      subject.should_receive(:registered_as).with(host).and_return(node_name)

      subject.registered?(host).should be_true
    end

    it "returns false if the target node is not registered with the Chef server" do
      subject.should_receive(:registered_as).with(host).and_return(nil)

      subject.registered?(host).should be_false
    end
  end

  describe "#registered_as" do
    let(:node_name) { "reset.riotgames.com" }
    let(:client) { double('client', name: node_name) }

    before do
      subject.stub(:node_name).with(host).and_return(node_name)
    end

    it "returns the name of the client the target node has registered to the Chef server" do
      subject.chef_connection.stub_chain(:client, :find).with(node_name).and_return(client)

      subject.registered_as(host).should eql(client.name)
    end

    it "returns nil if the target node does not have a client registered on the Chef server" do
      subject.chef_connection.stub_chain(:client, :find).with(node_name).and_return(nil)

      subject.registered_as(host).should be_nil
    end

    it "returns nil if we can't determine the node_name of the host" do
      subject.should_receive(:node_name).with(host).and_return(nil)

      subject.registered_as(host).should be_nil
    end

    context "when the target node's node_name cannot be resolved" do
      before do
        subject.stub(:node_name).with(host).and_return(nil)
      end

      it "returns false" do
        subject.registered_as(host).should be_false
      end
    end
  end

  describe "#async_enable" do
    let(:host) { "192.168.1.1" }
    let(:options) { Hash.new }

    it "creates a Job and delegates to #disable" do
      ticket = double('ticket')
      job    = double('job', ticket: ticket)
      MB::Job.should_receive(:new).and_return(job)
      subject.should_receive(:async).with(:enable, job, host, {})

      subject.async_enable(host)
    end

    it "returns a JobTicket" do
      expect(subject.async_enable(host)).to be_a(MB::JobRecord)
    end
  end


  describe "#enable" do
    let(:host) { "192.168.1.1" }
    let(:job) { MB::Job.new(:disable) }
    let(:future_stub) { double(Celluloid::Future, value: nil) }
    let(:node_stub) { 
      double(Ridley::NodeObject,
             run_list: ["recipe[disabled]", "recipe[foo::server]", "recipe[foo::database]"])
    }

    before do
      subject.stub(:registered_as).with(host).and_return(nil)
    end

    it "terminates the job" do
      begin
        subject.enable(job, host)
      rescue MB::NodeNotFound
        # Don't care
      end
      expect(job).to_not be_alive
    end

    context "when the node is not registered" do
      it "displays a warning" do
        job.should_receive(:report_failure)
        subject.enable(job, host)
      end
    end

    context "when the node is registered" do
      let(:node_name)     { "foo.riotgames.com" }
      let(:run_list)      { ["recipe[disabled]", "recipe[foo::server]", "recipe[bar::server]"] }
      let(:node)          { double(Ridley::NodeObject,
                                   name: node_name,
                                   run_list: run_list,
                                   save: true,
                                   chef_environment: environment) }
      let(:plugin_manager) { double(MB::PluginManager) }
      
      %w[foo bar].each do |x|
        let(:"service_#{x}_recipe") { "recipe[#{x}::service]" }

        let(:"#{x}_group")     { double(MB::Group,
                                        recipes: ["#{x}::server"]) }
        let(:"dynamic_#{x}_service") { double(MB::Gear::DynamicService) }
        let(:"#{x}_service")   { double(MB::Gear::Service,
                                        name: "#{x}_service",
                                        service_group: send(:"#{x}_group"),
                                        service_recipe: send(:"service_#{x}_recipe"),
                                        to_dynamic_service: send(:"dynamic_#{x}_service")) }
        let(:"#{x}_component") { double(MB::Component,
                                        name: "#{x}_component",
                                        group: send(:"#{x}_group")) }
        let(:"#{x}_plugin")    { double(MB::Plugin,
                                        components: [send(:"#{x}_component")]) }
        let(:"environment")   { "theenv" }
      end

      before do
        subject.stub(:registered_as).and_return(node_name)
      end

      it "enables the node" do
        subject.stub(:plugin_manager).and_return(plugin_manager)
        subject.stub_chain(:chef_connection, :node, :find).with(node_name).and_return(node)
        %w[foo bar].each_with_index do |x, i|
          plugin_manager
            .should_receive(:for_run_list_entry)
            .with(run_list[i+1], environment, remote: true)
            .and_return(send(:"#{x}_plugin"))
          send(:"#{x}_component").should_receive(:gears).with(MB::Gear::Service).and_return([send(:"#{x}_service")])
          send(:"#{x}_service").stub(:dynamic_service?).and_return(true)
          send(:"#{x}_group").should_receive(:includes_recipe?).with(run_list[i+1]).and_return(true)
          send(:"dynamic_#{x}_service").should_receive(:remove_node_state_change).with(job, send(:"#{x}_plugin"), node, false)
          node.stub(:run_list=)
        end
        subject.should_receive(:bulk_chef_run).with(job, [node], %w[foo bar].collect { |x| send(:"service_#{x}_recipe") })

        subject.enable(job, host)
      end
    end
  end

  describe "#async_purge" do
    let(:host) { "192.168.1.1" }
    let(:options) { Hash.new }

    it "creates a Job and delegates to #purge" do
      ticket = double('ticket')
      job    = double('job', ticket: ticket)
      MB::Job.should_receive(:new).and_return(job)
      subject.should_receive(:purge).with(job, host, options)

      subject.async_purge(host, options)
    end

    it "returns a JobTicket" do
      expect(subject.async_purge(host, options)).to be_a(MB::JobRecord)
    end
  end

  describe "#async_upgrade_omnibus"re do
    let(:host) { "192.168.1.1" }
    let(:nodes) { [Ridley::NodeObject.new(host, automatic: { fqdn: host })] }
    let(:version) { "11.12.4" }
    let(:options) { Hash.new }

    it "creates a Job and delegates to #upgrade_omnibus" do
      ticket = double('ticket')
      job    = double('job', ticket: ticket)
      MB::Job.should_receive(:new).and_return(job)
      subject.should_receive(:upgrade_omnibus).with(job, version, nodes, options)

      subject.async_upgrade_omnibus(version, nodes, options)
    end

    it "returns a JobTicket" do
      expect(subject.async_purge(host, options)).to be_a(MB::JobRecord)
    end
  end

  describe "#upgrade_omnibus" do
    let(:host) { "192.168.1.1" }
    let(:nodes) { [Ridley::NodeObject.new(host, automatic: { fqdn: host })] }
    let(:version) { "11.12.4" }
    let(:options) do
      {
        chef_version: version
      }
    end
    let(:job) { MB::Job.new(:upgrade_omnibus) }
    let(:future_stub) { double(Celluloid::Future, value: nil) }

    before do
      subject.chef_connection.
        stub_chain(:node, :future).
        with(:update_omnibus, host, options).
        and_return(future_stub)
    end

    context "when there are no errors" do
      it "reports success" do
        job.should_receive(:report_success)
        subject.upgrade_omnibus(job, version, nodes, options)
      end
    end

    it "terminates the job" do
      subject.upgrade_omnibus(job, version, nodes, options)
      expect(job).to_not be_alive
    end
  end

  describe "#async_disable" do
    let(:host) { "192.168.1.1" }
    let(:options) { Hash.new }

    it "creates a Job and delegates to #disable" do
      ticket = double('ticket')
      job    = double('job', ticket: ticket)
      MB::Job.should_receive(:new).and_return(job)
      subject.should_receive(:async).with(:disable, job, host, {})

      subject.async_disable(host)
    end

    it "returns a JobTicket" do
      expect(subject.async_disable(host)).to be_a(MB::JobRecord)
    end
  end

  describe "#disable" do
    let(:host) { "192.168.1.1" }
    let(:job) { MB::Job.new(:disable) }
    let(:future_stub) { double(Celluloid::Future, value: nil) }
    let(:node_stub) { 
      double(Ridley::NodeObject,
             run_list: ["recipe[foo::server]", "recipe[foo::database]"])
    }

    before do
      subject.stub(:registered_as).with(host).and_return(nil)
    end

    it "terminates the job" do
      subject.disable(job, host) rescue nil
      expect(job).to_not be_alive
    end

    context "when the node is not registered" do
      it "reports failure" do
        msg = "Could not discover the host's node name. The host may not be " +
          "registered with Chef or the embedded Ruby used to identify the " +
          "node name may not be available. #{host} was not disabled!"
        job.should_receive(:report_failure).with(msg).and_return { raise "exit" }
        begin
          subject.disable(job, host)
        rescue => e
          e.message.should == "exit"
        end
      end
    end

    context "when the node is registered" do
      let(:node_name)     { "foo.riotgames.com" }
      let(:run_list)      { ["recipe[foo::server]", "recipe[bar::server]"] }
      let(:node)          { double(Ridley::NodeObject,
                                   name: node_name,
                                   run_list: run_list,
                                   save: true,
                                   chef_environment: environment) }
      let(:plugin_manager) { double(MB::PluginManager) }
      
      %w[foo bar].each do |x|
        let(:"service_#{x}_recipe") { "recipe[#{x}::service]" }

        let(:"#{x}_group")     { double(MB::Group,
                                        recipes: ["#{x}::server"]) }
        let(:"dynamic_#{x}_service") { double(MB::Gear::DynamicService) }
        let(:"#{x}_service")   { double(MB::Gear::Service,
                                        name: "#{x}_service",
                                        service_group: send(:"#{x}_group"),
                                        service_recipe: send(:"service_#{x}_recipe"),
                                        to_dynamic_service: send(:"dynamic_#{x}_service")) }
        let(:"#{x}_component") { double(MB::Component,
                                        name: "#{x}_component",
                                        group: send(:"#{x}_group")) }
        let(:"#{x}_plugin")    { double(MB::Plugin,
                                        components: [send(:"#{x}_component")]) }
        let(:"environment")   { "theenv" }
      end
      
      it "disables the node" do
        subject.stub(:plugin_manager).and_return(plugin_manager)
        subject.should_receive(:registered_as).with(host).and_return(node_name)
        subject.stub_chain(:chef_connection, :node, :find).with(node_name).and_return(node)
        %w[foo bar].each_with_index do |x, i|
          plugin_manager
            .should_receive(:for_run_list_entry)
            .with(run_list[i], environment, remote: true)
            .and_return(send(:"#{x}_plugin"))
          send(:"#{x}_component").should_receive(:gears).with(MB::Gear::Service).and_return([send(:"#{x}_service")])
          send(:"#{x}_service").stub(:dynamic_service?).and_return(true)
          send(:"#{x}_group").should_receive(:includes_recipe?).with(run_list[i]).and_return(true)
          send(:"dynamic_#{x}_service").should_receive(:node_state_change).with(job, send(:"#{x}_plugin"), node, MB::Gear::DynamicService::STOP, false)
          node.should_receive(:run_list).and_return(run_list)
          node.stub(:run_list=)
        end
        subject.should_receive(:bulk_chef_run).with(job, [node], %w[foo bar].collect { |x| send(:"service_#{x}_recipe") })

        subject.disable(job, host)
       end
    end
  end

  describe "#async_purge" do
    let(:host) { "192.168.1.1" }
    let(:options) { Hash.new }

    it "creates a Job and delegates to #purge" do
      ticket = double('ticket')
      job    = double('job', ticket: ticket)
      MB::Job.should_receive(:new).and_return(job)
      subject.should_receive(:purge).with(job, host, options)

      subject.async_purge(host, options)
    end

    it "returns a JobTicket" do
      expect(subject.async_purge(host, options)).to be_a(MB::JobRecord)
    end
  end

  describe "#purge" do
    let(:host) { "192.168.1.1" }
    let(:job) { MB::Job.new(:purge) }
    let(:future_stub) { double(Celluloid::Future, value: nil) }

    before do
      subject.stub(:registered_as).with(host).and_return(nil)
      subject.chef_connection.
        stub_chain(:node, :future).
        with(:uninstall_chef, host, skip_chef: false).
        and_return(future_stub)
    end

    it "terminates the job" do
      subject.purge(job, host)
      expect(job).to_not be_alive
    end

    context "when the node is not registered" do
      it "uninstalls chef" do
        subject.purge(job, host)
      end
    end

    context "when the node is registered" do
      let(:node_name) { "reset.riotgames.com" }
      before { subject.should_receive(:registered_as).with(host).and_return(node_name) }

      it "deletes the client and node object and uninstalls chef" do
        subject.chef_connection.stub_chain(:client, :future).with(:delete, node_name).and_return(future_stub)
        subject.chef_connection.stub_chain(:node, :future).with(:delete, node_name).and_return(future_stub)
        subject.purge(job, host)
      end
    end
  end

  describe "#connector_for_os" do
    let(:connector_for_os) { subject.connector_for_os(os) }

    context "when the os is windows" do
      let(:os) { "windows" }

      it "returns winrm" do
        expect(connector_for_os).to eql("winrm")
      end
    end

    context "when the os is linux" do
      let(:os) { "linux" }

      it "returns ssh" do
        expect(connector_for_os).to eql("ssh")
      end
    end

    context "when the os is not windows or linux" do
      let(:os) { "solaris" }

      it "returns nil" do
        expect(connector_for_os).to be_nil
      end
    end
  end
end
