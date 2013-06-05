module MotherBrain
  class JobRecord
    include MB::Job::States

    attr_reader :id

    attr_reader :result
    attr_reader :state
    attr_reader :status
    attr_reader :status_buffer
    attr_reader :type

    attr_reader :time_start
    attr_reader :time_end

    # @param [Job] job
    def initialize(job)
      @id = job.id
      mass_assign(job)
    end

    # Update the instantiated JobRecord with the attributes of the given Job
    #
    # @param [Job] job
    #   the updated job to update the record with
    #
    # @return [self]
    def update(job)
      mass_assign(job)
      self
    end

    # @return [Hash]
    def to_hash
      {
        id: id,
        type: type,
        state: state,
        status: status,
        result: result,
        time_start: time_start,
        time_end: time_end
      }
    end

    # @param [Hash] options
    #   a set of options to pass to MultiJson.encode
    #
    # @return [String]
    def to_json(options = {})
      MultiJson.encode(self.to_hash, options)
    end

    private

      # @param [Job] job
      def mass_assign(job)
        @result        = job.result
        @state         = job.state
        @status        = job.status
        @status_buffer = job.status_buffer
        @time_end      = job.time_end
        @time_start    = job.time_start
        @type          = job.type
      end
  end
end
