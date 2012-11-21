require 'spec_helper'

describe MB::Provisioner do
  subject do
    Class.new do
      include MB::Provisioner
    end.new
  end

  it { subject.should respond_to(:up) }
  it { subject.should respond_to(:down) }
end
