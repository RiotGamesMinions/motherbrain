require 'spec_helper'

describe MB::Job do
  let(:type) { MB::Job::Type::PROVISION }

  describe "ClassMethods" do
    subject { described_class }

    describe "::create" do
      subject { described_class.new(type) }

      it "starts in PENDING state" do
        subject.should be_pending
      end

      it "starts with a nil result" do
        subject.result.should be_nil
      end

      it "has an ID" do
        subject.id.should_not be_nil
      end
    end
  end

  subject { described_class.new(type) }

  describe "#completed?" do
    it "should be completed if status is 'success'" do
      subject.stub(:status).and_return('success')

      subject.should be_completed
    end

    it "should be completed if status is 'failure'" do
      subject.stub(:status).and_return('failure')

      subject.should be_completed
    end

    it "should not be completed if status is 'pending'" do
      subject.stub(:status).and_return('pending')

      subject.should_not be_completed
    end

    it "should not be completed if status is 'running'" do
      subject.stub(:status).and_return('running')

      subject.should_not be_completed
    end
  end

  describe "#failure?" do
    it "should be a failure if status is 'failure'" do
      subject.stub(:status).and_return('failure')

      subject.should be_failure
    end

    it "should not be a failure if status is not 'failure'" do
      subject.stub(:status).and_return('success')

      subject.should_not be_failure
    end
  end

  describe "#pending?" do
    it "should be pending if status is 'pending'" do
      subject.stub(:status).and_return('pending')

      subject.should be_pending
    end

    it "should not be a pending if status is not 'pending'" do
      subject.stub(:status).and_return('success')
      
      subject.should_not be_pending
    end
  end

  describe "#running?" do
    it "should be running if status is 'running'" do
      subject.stub(:status).and_return('running')

      subject.should be_running
    end

    it "should not be running if status is not 'running'" do
      subject.stub(:status).and_return('success')

      subject.should_not be_running
    end
  end

  describe "#success?" do
    it "should be a success if status is 'success'" do
      subject.stub(:status).and_return('success')

      subject.should be_success
    end

    it "should not be success if status is not 'success'" do
      subject.stub(:status).and_return('failure')

      subject.should_not be_success
    end
  end

  describe "#ticket" do
    it "should return a JobTicket" do
      subject.ticket.should be_a(MB::JobTicket)
    end
  end

  describe "#transition" do
    pending
  end

  describe "#update" do
    pending
  end
end
