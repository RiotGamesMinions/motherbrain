module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Job
    class StateMachine
      include Celluloid::FSM
      include Celluloid::Notifications
      include MB::Logging

      state :pending, to: [ :running, :failure ], default: true do
        log.debug { "job (#{actor.id}) transitioning to '#{state}'" }
        publish('job.transition', actor)
      end

      state :running, to: [ :success, :failure ] do
        log.debug { "job (#{actor.id}) transitioning to '#{state}'" }
        publish('job.transition', actor)
      end

      state :success do
        log.debug { "job (#{actor.id}) transitioning to '#{state}'" }
        publish('job.transition', actor)
      end

      state :failure do
        log.debug { "job (#{actor.id}) transitioning to '#{state}'" }
        publish('job.transition', actor)
      end
    end

    extend Forwardable
    include Celluloid
    include MB::Logging

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

    # @param [Symbol] state
    # @param [#to_json] result
    #
    # @return [Job]
    def transition(state, result = nil, options = {})
      @result = result unless result.nil?
      machine.transition(state, options)
      Actor.current
    end

    def finalize
      JobManager.instance.remove(Actor.current)
    end

    def to_hash
      {
        id: self.id,
        type: self.type,
        state: self.state,
        result: self.result
      }
    end

    private

      attr_reader :machine
  end
end
