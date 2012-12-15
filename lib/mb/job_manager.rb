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
      mutex.synchronize do
        jobs.add(job)
      end
      job.dup
    end

    # @param [Integer] id
    #
    # @raise [JobNotFound] if no job found with given ID
    #
    # @return [Job]
    def find(id)
      job = jobs.find { |job| job.id == id }

      if job.nil?
        raise JobNotFound.new(id)
      end

      job
    end

    # @param [Integer] id
    #
    # @raise [JobNotFound] if no job found with given ID
    #
    # @return [JobTicket]
    def ticket_for(id)
      JobTicket.new(find(id).id)
    end

    # @param [Integer] id
    # @param [String] status
    # @param [#to_json] result
    #
    # @raise [ArgumentError] if an unknown job status is given
    # @raise [JobNotFound] if no job found with given ID
    #
    # @return [Job]
    def update(id, status, result)
      unless [FAILURE, PENDING, RUNNING, SUCCESS].include?(status)
        raise ArgumentError, "unknown job status given: #{status}"
      end

      job = nil

      mutex.synchronize do
        job = find(id)
        job.status = status
        job.result = result unless result.nil?
      end

      job.dup
    end

    private

      attr_reader :mutex
  end
end
