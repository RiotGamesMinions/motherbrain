require 'spec_helper'

describe MB::ClusterBootstrapper do
  let(:amq_master) { double('amq_master') }
  let(:amq_slave) { double('amq_slave') }
  let(:mysql_master) { double('mysql_master') }
  let(:mysql_slave) { double('mysql_slave') }
  let(:nginx_master) { double('nginx_master') }

  let(:activemq) do
    activemq = double('activemq')
    activemq.stub(:group!).with("master").and_return(amq_master)
    activemq.stub(:group!).with("slave").and_return(amq_slave)
    activemq
  end

  let(:mysql) do
    mysql = double('mysql')
    mysql.stub(:group!).with("master").and_return(mysql_master)
    mysql.stub(:group!).with("slave").and_return(mysql_slave)
    mysql
  end

  let(:nginx) do
    nginx = double('nginx')
    nginx.stub(:group!).with("master").and_return(nginx_master)
    nginx
  end

  let(:plugin) do
    plugin = double('plugin')
    plugin.stub(:component!).with("activemq").and_return(activemq)
    plugin.stub(:component!).with("mysql").and_return(mysql)
    plugin.stub(:component!).with("nginx").and_return(nginx)
    plugin
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
end
