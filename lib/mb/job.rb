module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Job
    autoload :Status, 'mb/job/status'

    class << self
      alias_method :old_new, :new

      # @param [String] type
      def create(type)
        JobManager.instance.create(type)
      end
      alias_method :new, :create

      private

        def __initialize__(id, type)
          old_new(id, type)
        end
    end

    include Job::Status

    attr_reader :id
    attr_reader :type
    
    attr_accessor :status
    attr_accessor :result

    alias_method :state, :status

    # @param [Integer] id
    # @param [#to_s] type
    def initialize(id, type)
      @id     = id
      @type   = type.to_s
      @status = PENDING
      @result = nil
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
      JobManager.instance.ticket_for(self.id)
    end

    # @param [String] status
    # @param [#to_json] result
    #
    # @return [Job]
    def transition(status, result = nil)
      JobManager.instance.update(self.id, status, result)
    end
  end
end
