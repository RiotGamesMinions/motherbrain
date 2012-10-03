require 'spec_helper'

describe MB::PluginDSL::Groups do
  subject do
    Class.new do
      include MB::PluginDSL::Groups
    end.new
  end

  before(:each) do
    subject.context = @context
    subject.real = double('real_object')
  end

  describe "#groups" do
    before(:each) do
      subject.group do
        name "master_databases"
      end      
    end

    it "returns a Hash" do
      subject.send(:groups).should be_a(Hash)
    end

    it "has an item for each group" do
      subject.send(:groups).should have(1).item
    end

    it "has a key for each group name" do
      subject.send(:groups).should have_key(:master_databases)
    end

    it "has a MB::Group for each value" do
      subject.send(:groups).values.should each be_a(MB::Group)
    end
  end

  describe "#group" do
    it "adds a group to the internal Hash of groups" do
      subject.group do
        name "master_databases"
      end

      groups = subject.send(:groups)
      groups.should have(1).item
      groups[:master_databases].should be_a(MB::Group)
      groups[:master_databases].name.should eql("master_databases")
    end

    context "when a group of the same name already exists" do
      it "raises a DuplicateGroup error" do
        subject.group do
          name "master_databases"
        end

        lambda {
          subject.group do
            name "master_databases"
          end
        }.should raise_error(MB::DuplicateGroup)
      end
    end
  end
end
