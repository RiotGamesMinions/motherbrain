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

    attr_reader :jobs
    alias_method :list, :jobs

    def initialize
      @jobs  = Set.new
      @mutex = Mutex.new
    end

    def create(type)
      job = Job.send(:__initialize__, 1, type)
      jobs.add(job)
      job
    end

    # @param [Integer] id
    #
    # @return [Job]
    def find(id)
      jobs.find { |job| job.id == id }
    end

    # @param [Integer] id
    #
    # @raise [JobNotFound] if no job found with given ID
    #
    # @return [Job]
    def find!(id)
      job = find(id)
      
      if job.nil?
        raise JobNotFound.new(id)
      end

      job
    end

    # @param [Integer] id
    # @param [String] status
    # @param [#to_json] message
    #
    # @return [ String, #to_json ]
    #   an array containing the job status and job result
    def transition(id, status, result)
      job = find!(id)
      job.status = status
      job.result = result if result

      [ job.status, job.result ]
    end
  end
end
