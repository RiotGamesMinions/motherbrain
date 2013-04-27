require 'spec_helper'

describe MB::Gear::Mysql do
  describe "Class" do
    subject { MB::Gear::Mysql }

    it "is registered with MB::Gear" do
      MB::Gear.all.should include(subject)
    end

    it "has the inferred keyword ':mysql' from it's Class name" do
      subject.keyword.should eql(:mysql)
    end
  end

  describe "#action" do
    subject { MB::Gear::Mysql.new }

    it "returns a Gear::Mysql::Action" do
      subject.action("select * from boxes", data_bag: {name: "creds"}).should be_a(MB::Gear::Mysql::Action)
    end
  end
end

describe MB::Gear::Mysql::Action do
  subject { MB::Gear::Mysql::Action }
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
      lambda { subject.new(sql, options) }.should raise_error(MB::ArgumentError)
    end

    it "should have a data bag name" do
      options = {data_bag: {}}
      lambda { subject.new(sql, options) }.should raise_error(MB::ArgumentError)

      options = {data_bag: {name: "creds"}}
      lambda { subject.new(sql, options) }.should_not raise_error(MB::ArgumentError)
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
        lambda { subject.connection_info(environment, node) }.should raise_error(MB::GearError)
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
