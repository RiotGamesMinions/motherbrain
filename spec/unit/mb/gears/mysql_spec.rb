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
    subject { MB::Gear::Mysql.new(@context) }

    it "returns a Gear::Mysql::Action" do
      subject.action("select * from boxes", data_bag: {name: "creds"}).should be_a(MB::Gear::Mysql::Action)
    end
  end
end

describe MB::Gear::Mysql::Action do
  subject { MB::Gear::Mysql::Action }
  let(:sql) { "select * from boxes" }

  describe "::new" do
    let(:options) { {data_bag: {name: "creds"}} }

    it "should set its attributes" do
      obj = subject.new(@context, sql, options)

      obj.sql.should == sql
      obj.options.should == options
    end
  end

  describe "options" do
    it "should describe a data bag" do
      options = {}
      lambda { subject.new(@context, sql, options) }.should raise_error(MB::GearError)
    end

    it "should have a data bag name" do
      options = {data_bag: {}}
      lambda { subject.new(@context, sql, options) }.should raise_error(MB::GearError)

      options = {data_bag: {name: "creds"}}
      lambda { subject.new(@context, sql, options) }.should_not raise_error(MB::GearError)
    end
  end

  describe "#connection_info" do
    let(:node) { double("node", public_hostname: "some.node.com") }
    let(:base_options) { {data_bag: {name: "creds"}} }

    before(:each) do
      subject.any_instance.stub(:environment).and_return("test_env")
    end

    it "should have a host" do
      obj = subject.new(@context, sql, base_options)

      connection_info = obj.connection_info(node)
      connection_info[:host].should == "some.node.com"
    end

    it "should have the correct adapter" do
      obj = subject.new(@context, sql, base_options)

      connection_info = obj.connection_info(node)
      if MB.jruby?
        connection_info[:adapter].should == "jdbcmysql"
      else
        connection_info[:adapter].should == "mysql2"
      end
    end
  end

  describe "#data_bag_keys" do
    let(:base_options) { {data_bag: {name: "creds"}} }
    let(:keys) { [:username, :password, :database, :port] }

    it "should have all of the keys" do
      obj = subject.new(@context, sql, base_options)
      keys.each { |key| obj.data_bag_keys.should have_key(key) }
    end

    it "should prepend the base hash" do
      options = base_options.dup
      options[:data_bag][:location] = {hash: "some.hash"}
      obj = subject.new(@context, sql, options)

      keys.each { |key| obj.data_bag_keys[key].should start_with("some.hash.") }
    end
  end
end
