module MotherBrain
  # @author Jamie Winsor <reset@riotgames.com>
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
    include MB::Mixin::Services

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

    finalizer do
      set_status("complete")
      job_manager.complete_job(Actor.current)
    end

    # @param [#to_s] type
    def initialize(type)
      @machine = StateMachine.new
      @type    = type.to_s
      @id      = job_manager.uuid
      @result  = nil
      job_manager.add(Actor.current)
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

    # @param [Boolean] boolean
    #   a boolean value representing a success or failure
    # @param [#to_json] result
    #   a result which can be converted to JSON
    # @param [Hash] options
    #   options to pass to the state machine transition
    #
    # @return [Job]
    def report_boolean(boolean, result = nil, options = {})
      if boolean
        report_success(result, options)
      else
        report_failure(result, options)
      end
    end

    # @return [self]
    def save
      job_manager.update(Actor.current)
    end

    def status
      @status || state.to_s.capitalize
    end

    def status=(string)
      @status = string
      save
    end
    alias_method :set_status, :status=

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

    def to_s
      "#<Job @type=#{type.inspect} @machine.state=#{state.inspect}>"
    end
    alias_method :inspect, :to_s

    private

      attr_reader :machine
  end
end
