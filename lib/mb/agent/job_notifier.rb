require 'chef/event_dispatch/base'

module MotherBrain::Agent
  # @author Jamie Winsor <reset@riotgames.com>
  class JobNotifier < ::Chef::EventDispatch::Base
    extend Forwardable

    attr_reader :job
    def_delegator :job, :set_status

    # @param [MB::Job]
    #   the job to update as a Chef run progresses
    def initialize(job)
      @job = job
    end

    def run_start(version)
      set_status("running chef #{version}")
    end
  end
end
