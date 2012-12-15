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
      @jobs  = Hash.new
      @mutex = Mutex.new
    end

    def create(type)
      1
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

    def transition(id, status)
      update(id, status: status)
    end

    def update(id, attributes = {})
      find!(id)
    end
  end
end
