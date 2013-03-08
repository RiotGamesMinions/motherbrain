require 'spec_helper'

describe MB::Mixin::AttributeSetting do
  subject do
    Class.new do
      include MB::Mixin::AttributeSetting
    end.new
  end

  let(:environment) { "test-env" }

  describe "#set_component_versions" do
    let(:plugin) { double('plugin', name: "rspec") }
    let(:component) { double('component') }

    context "when the component exists" do
      before(:each) { plugin.stub(:component!).with(plugin.name).and_return(component) }

      context "without a version_attribute" do
        before(:each) { component.stub(version_attribute: nil) }

        it "raises a MB::ComponentNotVersioned error" do
          expect {
            subject.set_component_versions(environment, plugin, plugin.name => "1.2.3")
          }.to raise_error(MB::ComponentNotVersioned)
        end
      end
    end

    context "when the component does not exist" do
      before(:each) do
        plugin.stub(:component!).with(plugin.name).and_raise(MB::ComponentNotFound.new(component, plugin))
      end

      it "raises a MB::ComponentNotFound error" do
        expect {
          subject.set_component_versions(environment, plugin, plugin.name => "1.2.3")
        }.to raise_error(MB::ComponentNotFound)
      end
    end
  end

  describe "#set_cookbook_versions" do
    context "successful" do
      let(:hash) { Hash.new }
      before(:each) do
        env = double('environment', name: "foo")
        Ridley::EnvironmentResource.stub(:find!).and_return(env)
        env.should_receive(:cookbook_versions).and_return(hash)
        env.stub(:save)

        Ridley::CookbookResource.stub(:latest_version).and_return("1.2.4")
      end

      it "saves the cookbook versions to the environment" do
        subject.set_cookbook_versions "foo", {"some_book" => "= 1.2.3"}
        hash["some_book"].should_not be_nil
        hash["some_book"].should eq("= 1.2.3")
      end

      it "converts 'latest' to a (=) constraint of the latest" do
        subject.set_cookbook_versions "foo", {"some_book" => "latest"}
        hash["some_book"].should_not be_nil
        hash["some_book"].should eq("= 1.2.4")
      end
    end

    context "given incomplete version constraints" do
      let(:constraints) do
        { "some_cook" => "123" }
      end

      let(:env) { double('environment', name: "foo") }

      before(:each) do
        subject.stub(:expand_latest_versions) { constraints }
        Ridley::EnvironmentResource.stub(:find!).and_return(env)
        env.stub(:save)
      end

      it "expands them to a fully qualified constraint format" do
        env.stub_chain(:cookbook_versions, :merge!).with("some_cook" => "= 123.0.0")
        subject.set_cookbook_versions "foo", constraints
      end
    end

    context "when constraints could not be satisfiied" do
      let(:constraints) do
        { "rspec_test" => "= 1.2.3", "rspec_fail_test" => ">= 2.0.0" }
      end

      before(:each) do
        subject.stub(:expand_latest_versions) { constraints }
      end

      it "raises an error" do
        subject.stub(:satisfies_constraints?).with(constraints).and_raise

        expect {
          subject.set_cookbook_versions "foo", constraints
        }.to raise_error
      end
    end
  end

  describe "#set_environment_attributes" do
    context "successful" do
      let(:hash) { Hash.new }
      before(:each) do
        env = double('environment', name: "foo")
        Ridley::EnvironmentResource.stub(:find!).and_return(env)
        env.should_receive(:override_attributes).and_return(hash)
        env.stub(:save)
      end

      it "should save the attributes to the environment" do
        subject.set_environment_attributes "foo", {"bar.baz" => "quux"}
        hash["bar"].should_not be_nil
        hash["bar"]["baz"].should eq("quux")
      end
    end
  end
end
