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

    # Set when the state of the Job changes from 'pending' to 'running'
    #
    # @note do not modify outside of the state machine
    #
    # @return [Time]
    attr_accessor :time_start

    # Set when the state of the Job changes from 'running' to 'sucess' or 'failure'
    #
    # @note do not modify outside of the state machine
    #
    # @return [Time]
    attr_accessor :time_end

    def_delegator :machine, :state

    # @param [#to_s] type
    def initialize(type)
      @machine = StateMachine.new
      @type    = type.to_s
      @id      = JobManager.instance.uuid
      @result  = nil
      JobManager.instance.add(Actor.current)
    end

    # @param [#to_json] result
    #   a result which can be converted to JSON
    # @param [Hash] options
    #   options to pass to the state machine transition
    #
    # @return [Job]
    def report_failure(result = nil, options = {})
      log.fatal { "Job (#{id}) failure: #{result}" }
      transition(:failure, result, options)
    end

    # @param [#to_json] result
    #   a result which can be converted to JSON
    # @param [Hash] options
    #   options to pass to the state machine transition
    #
    # @return [Job]
    def report_pending(result = nil, options = {})
      log.debug { "Job (#{id}) pending: #{result}" }
      transition(:pending, result, options)
    end

    # @param [#to_json] result
    #   a result which can be converted to JSON
    # @param [Hash] options
    #   options to pass to the state machine transition
    #
    # @return [Job]
    def report_running(result = nil, options = {})
      log.debug { "Job (#{id}) running: #{result}" }
      transition(:running, result, options)
    end

    # @param [#to_json] result
    #   a result which can be converted to JSON
    # @param [Hash] options
    #   options to pass to the state machine transition
    #
    # @return [Job]
    def report_success(result = nil, options = {})
      log.debug { "Job (#{id}) success: #{result}" }
      transition(:success, result, options)
    end

    # @return [self]
    def save
      JobManager.instance.update(Actor.current)
    end

    def status
      @status || state.to_s.capitalize
    end

    def status=(string)
      @status = string
      save
    end

    # @return [JobTicket]
    def ticket
      @ticket ||= JobTicket.new(self.id)
    end

    # @param [Symbol] state
    #   the state to transition to in the Job's state machine
    # @param [#to_json] result
    #   a result which can be converted to JSON
    # @param [Hash] options
    #   options to pass to the state machine transition
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

    def to_s
      "#<Job @type=#{type.inspect} @machine.state=#{state.inspect}>"
    end
    alias_method :inspect, :to_s

    private

      attr_reader :machine
  end
end
