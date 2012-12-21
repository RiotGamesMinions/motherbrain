module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  #
  # A proxy object around a {JobRecord} stored in the {JobManager}. This wrapper object can
  # be returned as a response of the public API to a consumer. A ticket will poll it's
  # referenced {JobRecord} in the {JobManager} for an update about a running or completed {Job}
  #
  # @api public
  class JobTicket < BasicObject
    # @param [Integer] id
    def initialize(id)
      @record = JobManager.instance.find(id)
    end

    private

      attr_reader :record

      def method_missing(method, *args, &block)
        record.send(method, *args, &block)
      end
  end
end
