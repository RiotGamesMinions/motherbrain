require 'spec_helper'

describe MB::ChefRunner do
  let(:valid_options) do
    {
      keys: "/tmp/id_rsa"
    }
  end

  describe "ClassMethods" do
    subject { MB::ChefRunner }

    describe "::new" do
      it "sets a default value for 'address_attribute'" do
        obj = subject.new(valid_options)

        obj.send(:address_attribute).should eql(MB::ChefRunner::DEFAULT_ADDRESS_ATTRIBUTE)
      end

      it "validates the given options" do
        subject.should_receive(:validate_options).with(valid_options).and_return(true)
        
        subject.new(valid_options)
      end

      context "given value for option 'address_attribute'" do
        it "sets the private 'address_attribute' attribute" do
          obj = subject.new(valid_options.merge(address_attribute: 'network.en1.ipaddress'))

          obj.send(:address_attribute).should eql('network.en1.ipaddress')
        end
      end
    end

    describe "::validate_options" do
      context "given a value for 'keys'" do
        let(:options) do
          {
            keys: "/tmp/id_rsa"
          }
        end

        it "returns true" do
          subject.validate_options(options).should be_true
        end
      end

      context "given a value for 'user' and 'password'" do
        let(:options) do
          {
            user: "reset",
            password: "fake_pass"
          }
        end

        it "returns true" do
          subject.validate_options(options).should be_true
        end
      end

      context "given a value for 'user', 'password', and 'keys'" do
        let(:options) do
          {
            keys: "/tmp/id_rsa",
            user: "reset",
            password: "fake_pass"
          }
        end

        it "raises an ArgumentError" do
          lambda {
            subject.validate_options(options)
          }.should raise_error(MB::ArgumentError)
        end
      end

      context "given no value for 'user' and 'password' or 'keys'"  do
        let(:options) { Hash.new }

        it "raises an ArgumentError" do
          lambda {
            subject.validate_options(options)
          }.should raise_error(MB::ArgumentError)
        end
      end
    end

    describe "::handle_response" do
      context "when the response contains no failures" do
        let(:response) do
          [
            double('host1', exit_status: 0),
            double('host2', exit_status: 0)
          ]
        end

        before(:each) { @handled = subject.handle_response(response) }

        it "returns an array of two items" do
          @handled.should be_a(Array)
          @handled.should have(2).items
        end

        it "has the symbol :ok for the first element" do
          @handled[0].should eql(:ok)
        end

        it "has an empty error array for the second element" do
          @handled[1].should be_empty
        end
      end

      context "when the response contains failures" do
        let(:host1) { double('host1', exit_status: 0) }
        let(:host2) do
          double('host2',
            exit_status: 1,
            to_hash: {
              exit_status: 1,
              exit_signal: nil,
              stderr: [],
              stdout: []
            }
          )
        end
        let(:response) do
          [
            host1,
            host2
          ]
        end

        before(:each) { @handled = subject.handle_response(response) }

        it "returns an array of two items" do
          @handled.should be_a(Array)
          @handled.should have(2).items
        end

        it "has the symbol :error for the first element" do
          @handled[0].should eql(:error)
        end

        it "has an error array of hashes" do
          @handled[1].should have(1).item
          @handled[1].should each be_a(Hash)
        end

        it "has an exit_status, exit_signal, stderr, and stdout key for each error" do
          @handled[1].should each have_key(:exit_status)
          @handled[1].should each have_key(:exit_signal)
          @handled[1].should each have_key(:stderr)
          @handled[1].should each have_key(:stdout)
        end
      end
    end
  end

  let(:automatic_attributes) do
    HashWithIndifferentAccess.new(fqdn: "reset.dev.riotgames.com")
  end

  let(:node) do
    double('node', automatic: automatic_attributes)
  end

  subject { MB::ChefRunner.new(valid_options) }

  describe "#add_node" do
    it "returns a Rye::Set" do
      subject.add_node(node).should be_a(Rye::Set)
    end

    it "adds a nodes to the list of nodes" do
      subject.add_node(node)

      subject.nodes.should have(1).item
    end

    context "given a node that does not have a value for ipaddress at the given address_attribute" do
      subject { MB::ChefRunner.new(valid_options.merge(address_attribute: 'network.en0.ipaddress')) }

      it "raises an error" do
        lambda {
          subject.add_node(node)
        }.should raise_error(MB::NoValueForAddressAttribute)
      end
    end
  end

  describe "#add_nodes" do
    let(:node_1) { double('node_1') }
    let(:node_2) { double('node_2') }
    let(:nodes) do
      [
        node_1,
        node_2
      ]
    end

    it "calls add node for every node" do
      subject.should_receive(:add_node).with(node_1)
      subject.should_receive(:add_node).with(node_2)

      subject.add_nodes(nodes)
    end

    context "given one node" do
      it "calls add node for the one node" do
        subject.should_receive(:add_node).with(node_1)

        subject.add_nodes(node_1)
      end
    end
  end

  describe "#run" do
    let(:response) { double('response') }

    it "runs chef_client on the connection and handles the response" do
      subject.connection.should_receive(:chef_client).and_return(response)
      subject.class.should_receive(:handle_response).with(response).and_return(true)

      subject.run.should eql(true)
    end
  end
end
