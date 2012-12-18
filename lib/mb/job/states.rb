module MotherBrain
  class Job
    # @author Jamie Winsor <jamie@vialstudios.com>
    module States
      attr_reader :state
      
      # @return [Boolean]
      def completed?
        self.success? || self.failure?
      end
      alias_method :finished?, :completed?

      # @return [Boolean]
      def failure?
        self.state == :failure
      end

      # @return [Boolean]
      def pending?
        self.state == :pending
      end

      # @return [Boolean]
      def running?
        self.state == :running
      end

      # @return [Boolean]
      def success?
        self.state == :success
      end
    end
  end
end
