module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Job
    autoload :Status, 'mb/job/status'
    autoload :Type, 'mb/job/type'

    include Job::Status
    include Job::Type

    attr_reader :id
    attr_reader :type
    attr_reader :status
    attr_reader :messages

    alias_method :state, :status

    # @param [String] type
    def initialize(type)
      @id       = job_manager.create(type)
      @type     = type
      @status   = PENDING
      @messages = Array.new
    end

    # @return [Boolean]
    def completed?
      self.status == SUCCESS || self.status == FAILURE
    end
    alias_method :finished?, :completed?

    # @return [Boolean]
    def failure?
      self.status == FAILURE
    end

    # @return [Boolean]
    def pending?
      self.status == PENDING
    end

    # @return [Boolean]
    def running?
      self.status == RUNNING
    end

    # @return [Boolean]
    def success?
      self.status == SUCCESS
    end

    # @return [JobTicket]
    def ticket
      @ticket ||= JobTicket.new(self.id)
    end

    # @param [String] status
    #
    # @return [Job]
    def transition(status)
      @status = job_manager.transition(self.id, status)
      self
    end

    # @param [String] message
    #
    # @return [Job]
    def update(message)
      @messages = job_manager.update(self.id, message)
      self
    end

    private

      def job_manager
        JobManager.instance
      end
  end
end
