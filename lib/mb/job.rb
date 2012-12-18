module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  #
  # A Celluloid actor representing an active job. Jobs are handled by the {JobManager}
  # and should not be returned to a consumer or user from the Public API.
  #
  # Jobs start in the 'pending' state and can only be in any one state at a given
  # time. A Job is completed when in the 'success' or 'failure' state.
  #
  # The progress of a Job is recorded by the {JobManager} as a {JobRecord}. API
  # consumers should reference the status of a running Job by it's {JobRecord}.
  #
  # Returning a {JobTicket} from the Public API will give a consumer or user an easy
  # way to check the status of a job by polling a Job's {JobRecord}.
  #
  # @example running a job and checking it's status
  #
  #   job = Job.new('example_job')
  #   ticket = job.ticket
  #
  #   ticket.completed? => false
  #   ticket.state => :pending
  #
  #   job.transition(:success, 'done!')
  #
  #   ticket.completed? => true
  #   ticket.state => :success
  #
  # @api private
  class Job
    autoload :StateMachine, 'mb/job/state_machine'
    autoload :States, 'mb/job/states'

    extend Forwardable

    include Celluloid
    include MB::Logging
    include MB::Job::States

    attr_reader :id
    attr_reader :type
    attr_reader :result

    def_delegator :machine, :state

    # @param [#to_s] type
    def initialize(type)
      @machine = StateMachine.new
      @type    = type.to_s
      @id      = JobManager.instance.uuid
      @result  = nil
      JobManager.instance.add(Actor.current)
    end

    # @return [self]
    def save
      JobManager.instance.update(Actor.current)
    end

    # @return [JobTicket]
    def ticket
      @ticket ||= JobTicket.new(self.id)
    end

    # @param [Symbol] state
    # @param [#to_json] result
    # @param [Hash] options
    #
    # @return [Job]
    def transition(state, result = nil, options = {})
      @result = result
      machine.transition(state, options)
      Actor.current
    end

    def finalize
      JobManager.instance.complete_job(Actor.current)
    end

    private

      attr_reader :machine
  end
end
