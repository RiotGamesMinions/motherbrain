module MotherBrain
  class Job
    # A mixin to provide helper functions around the state of a Job, JobRecord, or
    # JobTicket. The helper functions are based on states set by {Job::StateMachine}
    module States
      attr_reader :state

      # If a job has succeeded or failed it considered completed
      #
      # @return [Boolean]
      def completed?
        self.success? || self.failure?
      end
      alias_method :finished?, :completed?

      # If a job has failed it is considered a failure
      #
      # @return [Boolean]
      def failure?
        self.state == :failure
      end
      alias_method :failed?, :failure?

      # If a job has not begun and is in the pending state it is considered pending
      #
      # @return [Boolean]
      def pending?
        self.state == :pending
      end

      # If a job has begun running and is in the running state it is considered running
      #
      # @return [Boolean]
      def running?
        self.state == :running
      end

      # If a job has succeeded it is considered a success
      #
      # @return [Boolean]
      def success?
        self.state == :success
      end
    end
  end
end
