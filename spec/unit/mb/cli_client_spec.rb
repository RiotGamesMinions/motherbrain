require 'spec_helper'

describe MB::CliClient do
  subject { cli_client }

  let(:cli_client) { CliClient.new job }
  let(:job) { job.new :job_name }

  pending
end
