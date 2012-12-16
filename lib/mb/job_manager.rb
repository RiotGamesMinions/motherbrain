module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class JobManager
    class << self
      # @raise [Celluloid::DeadActorError] if job manager has not been started
      #
      # @return [Celluloid::Actor(JobManager)]
      def instance
        Celluloid::Actor[:job_manager] or raise Celluloid::DeadActorError, "job manager not running"
      end
    end

    include Celluloid
    include Celluloid::Notifications
    include MB::Logging

    trap_exit :force_close

    attr_reader :jobs

    def initialize
      @jobs  = Set.new
      @mutex = Mutex.new
      subscribe('job.transition', :save)
    end

    def add(job)
      mutex.synchronize do
        jobs.add(job)
        monitor(job)
      end
    end

    def find(id)
      jobs.find { |job| job.id == id }
    end

    def remove(job)
      mutex.synchronize do
        jobs.delete(job)

        if job.alive?
          unmonitor(job)
        end
      end
    end

    # @param [String] _msg
    # @param [Job] job
    #
    # @raise [ArgumentError] if an unknown job status is given
    # @raise [JobNotFound] if no job found with given ID
    #
    # @return [Job]
    def save(_msg, job)
      log.debug { "updating job #{job.id}" }
    end

    def uuid
      Celluloid::UUID.generate
    end

    def force_close(actor, reason)
      log.warn { "job crashed: #{reason}" }
      remove(actor)
    end

    def finalize
      jobs.map { |job| job.terminate if job.alive? }
    end

    private

      attr_reader :mutex
  end
end
