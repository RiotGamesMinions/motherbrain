require 'spec_helper'

describe MB::FileSystem::Tempfile do
  subject { described_class }

  describe "::new" do
    it "creates a new temp file within MB's temp file system" do
      file = subject.new
      file.close

      file.path.should include(MB::FileSystem.tmp.to_s)
    end
  end
end
