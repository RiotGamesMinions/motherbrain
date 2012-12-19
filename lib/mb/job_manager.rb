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
    include MB::Logging

    trap_exit :force_complete

    # @return [Set<Job>]
    #   listing of all active jobs
    attr_reader :active

    # @return [Set<JobRecord>]
    #   listing of records of all jobs; completed and active
    attr_reader :records
    alias_method :list, :records

    def initialize
      @records = Set.new
      @active  = Set.new
    end

    # Track and record the given job
    #
    # @param [Job] job
    def add(job)
      active.add(job)
      records.add JobRecord.new(job)
      monitor(job)
    end

    # Complete the given active job
    #
    # @param [Job] job   
    def complete_job(job)
      active.delete(job)

      if job.alive?
        unmonitor(job)
      end
    end

    # @param [String] id
    def find(id)
      records.find { |record| record.id == id }
    end

    # Update the record for the given Job
    #
    # @param [Job] job
    def update(job)
      find(job.id).update(job)
    end

    # Generate a new Job ID
    #
    # @return [String]
    def uuid
      Celluloid::UUID.generate
    end

    def finalize
      active.map { |job| job.terminate if job.alive? }
    end

    private

      def force_complete(actor, reason)
        log.warn { "job crashed: #{reason}" }
        complete_job(actor)
      end
  end
end
