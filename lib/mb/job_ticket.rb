module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  #
  # A thin wrapper around a record stored in the {JobManager}. This wrapper object can
  # be returned as a response of the public API to a consumer. A ticket will poll it's
  # referenced {JobRecord} in the {JobManager} for an update about a running or completed {Job}
  #
  # @api public
  class JobTicket
    extend Forwardable
    include MB::Job::States

    attr_reader :id

    def_delegator :record, :type
    def_delegator :record, :state
    def_delegator :record, :result
    def_delegator :record, :time_start
    def_delegator :record, :time_end

    # @param [Integer] id
    def initialize(id)
      @id = id
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

      # @return [JobRecord]
      def record
        JobManager.instance.find(id)
      end
  end
end
