require 'spec_helper'

describe MB::AuthManager do
  describe "ClassMethods" do
    subject { described_class }

    describe "#secret_path" do
      it "returns a Pathname" do
        subject.secret_path.should be_a(Pathname)
      end
    end
  end

  subject { described_class.new }

  describe "#record_secret" do
    it "saves the contents of an AuthSecret to the secret path" do
      subject.record_secret("SOME_SECRET")

      File.should exist(subject.class.secret_path)
    end
  end

  describe "#secret" do
    context "when a secret file is present" do
      it "returns an AuthSecret" do
        subject.secret.should be_a(MB::AuthSecret)
      end
    end

    context "when a secret file is not present" do
      it "returns nil" do
        FileUtils.rm_f(subject.class.secret_path)

        subject.secret.should be_nil
      end
    end
  end
end
