require 'spec_helper'

describe MB::Gear::MySQL::Action do
  subject { described_class }
  let(:environment) { "rspec-test" }
  let(:sql) { "select * from boxes" }
  let(:base_options) { {data_bag: {name: "creds"}} }

  describe "::new" do
    it "should set its attributes" do
      obj = subject.new(sql, base_options)

      obj.sql.should == sql
      obj.options.should == base_options
    end
  end

  describe "options" do
    it "should describe a data bag" do
      options = {}
      expect { subject.new(sql, options) }.to raise_error(MB::ArgumentError)
    end

    it "should have a data bag name" do
      options = {data_bag: {}}
      expect { subject.new(sql, options) }.to raise_error(MB::ArgumentError)

      options = {data_bag: {name: "creds"}}
      expect { subject.new(sql, options) }.not_to raise_error
    end
  end

  describe "#connection_info" do
    let(:node) { double("node", public_hostname: "some.node.com") }
    let(:data_bag_item) { double("data_bag_item") }
    let(:data_bag) { double("data_bag") }
    subject { described_class.new(sql, base_options) }

    before(:each) do
      subject.ridley.stub_chain(:data_bag, :find).and_return(data_bag)
      data_bag.stub_chain(:item, :find).and_return(data_bag_item)
    end

    context "the data bag is empty" do
      before(:each) do
        data_bag_item.stub(:decrypt).and_return({})
      end

      it "should raise a GearError" do
        expect { subject.connection_info(environment, node) }.to raise_error(MB::GearError)
      end
    end

    context "the data bag is not empty" do
      before(:each) do
        data_bag_hash = {username: "user", password: "pass", database: "db", port: 3306}
        data_bag_item.stub(:decrypt).and_return(data_bag_hash)
      end

      it "should have a host" do
        connection_info = subject.connection_info(environment, node)

        connection_info[:host].should == "some.node.com"
      end

      it "should retrieve the credentials from the data bag" do
        connection_info = subject.connection_info(environment, node)

        connection_info[:username].should == "user"
        connection_info[:password].should == "pass"
        connection_info[:database].should == "db"
        connection_info[:port].should == 3306
      end
    end

    context "when the data bag does not exist" do
      before do
        subject.should_receive(:credentials).with(environment).and_raise(MB::DataBagNotFound.new("kittens"))
      end

      it "raises a GearError" do
        expect {
          subject.connection_info(environment, node)
        }.to raise_error
      end
    end

    context "when the data bag item does not exist" do
      before do
        subject.should_receive(:credentials).with(environment).
          and_raise(MB::DataBagItemNotFound.new("kittens", "puppies"))
      end

      it "raises a GearError" do
        expect {
          subject.connection_info(environment, node)
        }.to raise_error
      end
    end
  end

  describe "#data_bag_keys" do
    let(:keys) { [:username, :password, :database, :port] }

    it "should have all of the keys" do
      obj = subject.new(sql, base_options)
      keys.each { |key| obj.data_bag_keys.should have_key(key) }
    end

    it "should prepend the base hash" do
      options = base_options.dup
      options[:data_bag][:location] = {hash: "some.hash"}
      obj = subject.new(sql, options)

      keys.each { |key| obj.data_bag_keys[key].should start_with("some.hash.") }
    end
  end
end
