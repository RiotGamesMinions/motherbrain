module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class JobRecord
    include MB::Job::States

    attr_reader :id
    attr_reader :type
    attr_reader :state
    attr_reader :result
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
        result: result,
        time_start: time_start,
        time_end: time_end
      }
    end

    # @param [Hash] options
    #
    # @return [String]
    def to_json(options = {})
      MultiJson.encode(self.to_hash, options)
    end

    private

      def mass_assign(job)
        @type       = job.type
        @state      = job.state
        @result     = job.result
        @time_start = job.time_start
        @time_end   = job.time_end
      end
  end
end
