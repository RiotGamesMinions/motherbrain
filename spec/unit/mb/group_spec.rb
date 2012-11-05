require 'spec_helper'

describe MotherBrain::Group do
  let(:environment) { "mb-test" }

  before(:each) do
    @context = @context.dup
    @context.environment = environment
  end

  describe "ClassMethods" do
    subject { MotherBrain::Group }

    describe "::new" do
      context "given a block with multiple recipe calls" do
        it "adds each recipe to the array of recipes on the instantiated Group" do
          obj = subject.new("bacon", @context) do
            recipe "bacon::default"
            recipe "bacon::database"
          end

          obj.recipes.should have(2).items
          obj.recipes.should include("bacon::default")
          obj.recipes.should include("bacon::database")
        end
      end

      context "given a block with multiple role calls" do
        it "adds each role to the array of roles on the instantiated Group" do
          obj = subject.new("roles_are_poopy", @context) do
            role "roles_are_evil"
            role "stop_using_roles"
          end

          obj.roles.should have(2).items
          obj.roles.should include("roles_are_evil")
          obj.roles.should include("stop_using_roles")
        end
      end

      context "when an attribute of the same name is defined" do
        it "raises a DuplicateGroup error" do
          lambda {
            subject.new("db_master", @context) do
              chef_attribute "pvpnet.database.master", true
              chef_attribute "pvpnet.database.master", false
            end
          }.should raise_error(MotherBrain::DuplicateChefAttribute)
        end
      end
    end
  end

  describe "#name" do
    subject do
      MotherBrain::Group.new("master_database", @context) do
        # block
      end
    end

    it "returns the name of the Group" do
      subject.name.should eql("master_database")
    end
  end

  describe "#recipes" do
    subject do
      MotherBrain::Group.new("pvpnet", @context) do
        recipe "pvpnet::default"
        recipe "pvpnet::database"
        recipe "pvpnet::app"
      end
    end

    it "returns a Set of recipes" do
      subject.recipes.should be_a(Set)
    end

    it "includes all of the recipes from the block passed to Group.new" do
      subject.recipes.should have(3).items
      subject.recipes.should include("pvpnet::default")
      subject.recipes.should include("pvpnet::database")
      subject.recipes.should include("pvpnet::app")
    end

    context "when a recipe of the same name is defined" do
      subject do
        MotherBrain::Group.new("pvpnet", @context) do
          recipe "pvpnet::default"
          recipe "pvpnet::default"
        end
      end

      it "does not add a duplicate recipe" do
        subject.recipes.should have(1).item
      end
    end
  end

  describe "#roles" do
    subject do
      MotherBrain::Group.new("roles_are_poopy", @context) do
        role "stop"
        role "fucking"
        role "using"
        role "roles"
      end
    end

    it "returns a Set of roles" do
      subject.roles.should be_a(Set)
    end

    it "includes all of the roles from the block passed to Group.new" do
      subject.roles.should have(4).items
      subject.roles.should include("stop")
      subject.roles.should include("fucking")
      subject.roles.should include("using")
      subject.roles.should include("roles")
    end

    context "when a role of the same name is defined" do
      subject do
        MotherBrain::Group.new("roles_are_poopy", @context) do
          role "asshole_role"
          role "asshole_role"
        end
      end

      it "does not add a duplicate role" do
        subject.roles.should have(1).item
      end
    end
  end

  describe "#chef_attributes" do
    subject do
      MotherBrain::Group.new("db_master", @context) do
        chef_attribute "pvpnet.database.master", true
        chef_attribute "pvpnet.database.slave", false
      end
    end

    it "returns a Hash" do
      subject.chef_attributes.should be_a(Hash)
    end

    it "has a key for every chef_attribute" do
      subject.chef_attributes.should have_key("pvpnet.database.master")
      subject.chef_attributes.should have_key("pvpnet.database.slave")
    end

    it "has the value for every chef_attribute" do
      subject.chef_attributes["pvpnet.database.master"].should eql(true)
      subject.chef_attributes["pvpnet.database.slave"].should eql(false)
    end
  end

  describe "#search_query" do
    context "with one chef attribute" do
      subject do
        MotherBrain::Group.new("db_master", @context) do
          chef_attribute "pvpnet.database.master", true
        end
      end

      it "returns one key:value search string" do
        subject.search_query.should eql("chef_environment:#{environment} AND pvpnet_database_master:true")
      end
    end

    context "with multiple chef attributes" do
      subject do
        MotherBrain::Group.new("db_master", @context) do
          chef_attribute "pvpnet.database.master", true
          chef_attribute "pvpnet.database.slave", false
        end
      end

      it "returns them escaped and joined together by AND" do
        subject.search_query.should eql("chef_environment:#{environment} AND pvpnet_database_master:true AND pvpnet_database_slave:false")
      end
    end

    context "with multiple recipes" do
      subject do
        MotherBrain::Group.new("pvpnet", @context) do
          recipe "pvpnet::default"
          recipe "pvpnet::database"
        end
      end

      it "returns them escaped and joined together by AND" do
        subject.search_query.should eql("chef_environment:#{environment} AND run_list:recipe\\[pvpnet\\:\\:default\\] AND run_list:recipe\\[pvpnet\\:\\:database\\]")
      end
    end

    context "with multiple roles" do
      subject do
        MotherBrain::Group.new("roles", @context) do
          role "app_server"
          role "database_server"
        end
      end

      it "returns them escaped and joined together by AND" do
        subject.search_query.should eql("chef_environment:#{environment} AND run_list:role\\[app_server\\] AND run_list:role\\[database_server\\]")
      end
    end
  end
end
