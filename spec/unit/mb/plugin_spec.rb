require 'spec_helper'

describe MB::Plugin do
  describe "ClassMethods" do
    describe "::load" do
      subject { MB::Plugin }

      let(:bare_def) do
        <<-EOH
          name 'reset'
          version '1.2.3'
        EOH
      end

      it "returns an instance of MB::Plugin" do
        subject.load(@context, bare_def).should be_a(MB::Plugin)
      end

      it "sets the evaluated value for name" do
        data = <<-EOH
          name 'reset'
          version '1.2.3'
        EOH

        subject.load(@context, data).name.should eql('reset')
      end

      it "sets the evaluated value for version" do
        data = <<-EOH
          name 'reset'
          version '1.2.3'
        EOH

        subject.load(@context, data).version.to_s.should eql('1.2.3')
      end

      it "sets the evaluated value for description" do
        data = <<-EOH
          name 'reset'
          version '1.2.3'
          description 'a good plugin'
        EOH

        subject.load(@context, data).description.should eql('a good plugin')
      end

      it "sets the evaluated value for author" do
        data = <<-EOH
          name 'reset'
          version '1.2.3'
          author 'Jamie Winsor'
        EOH

        subject.load(@context, data).author.should eql('Jamie Winsor')
      end

      it "sets the evaluated value for email" do
        data = <<-EOH
          name 'reset'
          version '1.2.3'
          email 'jamie@vialstudios.com'
        EOH

        subject.load(@context, data).email.should eql('jamie@vialstudios.com')
      end

      context "when the string contains an invalid Plugin description" do
        it "raises an InvalidPlugin error" do
          data = <<-EOH
            name 1
            version '1.2.3'
          EOH

          lambda {
            subject.load(@context, data)
          }.should raise_error(MB::InvalidPlugin)
        end
      end
    end
  end

  describe MB::PluginProxy do
    subject { MB::PluginProxy.new(@context) }

    describe "#name" do
      it "sets the given value to the name attribute" do
        subject.name("reset")

        subject.attributes[:name].should eql("reset")
      end

      context "when the given value is nil" do
        it "raises a MB::ValidationFailed error" do
          lambda {
            subject.name(nil)
          }.should raise_error(MB::ValidationFailed)
        end
      end
    end

    describe "#version" do
      it "converts the string to a Solve::Version" do
        subject.version("1.2.3")

        subject.attributes[:version].should be_a(Solve::Version)
      end

      it "sets the given value to the version attribute" do
        subject.version("1.2.3")

        subject.attributes[:version].to_s.should eql("1.2.3")
      end

      context "when the given value is not a valid version string" do
        it "raises a MB::ValidationFailed error" do
          lambda {
            subject.version("123-321")
          }.should raise_error(MB::ValidationFailed, "'123-321' did not contain a valid version string: 'x.y.z' or 'x.y'.")
        end
      end
    end

    describe "#description" do
      it "sets the given value to the description attribute" do
        subject.description("a description")

        subject.attributes[:description].should eql("a description")
      end

      context "when the given value is not a string" do
        it "raises a MB::ValidationFailed error" do
          lambda {
            subject.description(1)
          }.should raise_error(MB::ValidationFailed)
        end
      end
    end

    describe "#author" do
      it "sets the given string to the author attribute" do
        subject.author("Jamie Winsor")

        subject.attributes[:author].should eql("Jamie Winsor")
      end

      it "sets the given array to the author attribute" do
        subject.author(["Jamie Winsor"])

        subject.attributes[:author].should eql(["Jamie Winsor"])
      end

      context "when the given value is not a string or Array" do
        it "raises a MB::ValidationFailed error" do
          lambda {
            subject.author(1)
          }.should raise_error(MB::ValidationFailed)
        end
      end
    end

    describe "#email" do
      it "sets the given string to the email attribute" do
        subject.email("jamie@vialstudios.com")

        subject.attributes[:email].should eql("jamie@vialstudios.com")
      end

      it "sets the given array to the email attribute" do
        subject.email(["jamie@vialstudios.com"])

        subject.attributes[:email].should eql(["jamie@vialstudios.com"])
      end

      context "when the given value is not a string or Array" do
        it "raises a MB::ValidationFailed error" do
          lambda {
            subject.email(1)
          }.should raise_error(MB::ValidationFailed)
        end
      end
    end

    describe "#nodes" do
      pending
    end
  end
end
