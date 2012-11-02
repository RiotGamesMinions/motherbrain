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
      subject.boot_tasks.should have(3).items
    end

    it "has a proc entry for each bootstrap function call" do
      subject.boot_tasks[2].should be_a(Proc)
    end

    it "has an array of procs for each async function call" do
      subject.boot_tasks[0].should each be_a(Proc)
      subject.boot_tasks[1].should each be_a(Proc)
    end
  end
end
