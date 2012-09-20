require 'spec_helper'

describe MB::Group do
  subject "ClassMethods" do
    subject { MB::Group }

    describe "::initialize" do
      context "given a block with multiple recipe calls" do
        it "adds each recipe to the array of recipes on the instantiated Group" do
          obj = subject.new(:app) do
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
          obj = subject.new(:app) do
            role "roles_are_evil"
            role "stop_using_roles"
          end

          obj.roles.should have(2).items
          obj.roles.should include("roles_are_evil")
          obj.roles.should include("stop_using_roles")
        end
      end
    end
  end

  subject { MB::Group.new(:app) }

  describe "#recipe" do
    it "returns an array" do
      subject.recipe("bacon::default").should be_a(Array)
    end

    it "adds the given recipe to the array of recipes" do
      subject.recipe("bacon::default")

      subject.recipes.should have(1).item
      subject.recipes.should include("bacon::default")
    end

    context "when a recipe that has already been added is added" do
      it "does not add the recipe a second time" do
        subject.recipe("bacon::default")
        subject.recipe("bacon::default")

        subject.recipes.should have(1).item
      end
    end
  end

  describe "#role" do
    it "returns an array" do
      subject.role("roles_are_evil").should be_a(Array)
    end

    it "adds the given role to the array of roles" do
      subject.role("roles_are_evil")

      subject.roles.should have(1).item
      subject.roles.should include("roles_are_evil")
    end

    context "when a role that has already been added is added" do
      it "does not add the role a second time" do
        subject.role("roles_are_evil")
        subject.role("roles_are_evil")

        subject.roles.should have(1).item
      end
    end
  end
end
