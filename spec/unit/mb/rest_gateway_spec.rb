require 'spec_helper'

describe MB::RestGateway do
  include Rack::Test::Methods

  after { subject.terminate }

  describe "#app" do
    it "returns MB::API::Application" do
      subject.app.should be_a(MB::API::Application)
    end
  end

  describe "constants" do
    it "should set DEFAULT_PORT to $PORT" do
      p = 12345
      ENV["PORT"] = p.to_s
      load File.join(File.dirname(__FILE__), "..", "..", "..", "lib", "mb", "rest_gateway.rb")
      expect(MB::RestGateway::DEFAULT_PORT).to eq(p)
    end

    it "should set DEFAULT_PORT to 26100 if $PORT is not set" do
      ENV.delete("PORT")
      load File.join(File.dirname(__FILE__), "..", "..", "..", "lib", "mb", "rest_gateway.rb")
      expect(MB::RestGateway::DEFAULT_PORT).to eq(26100)
    end
  end
end
