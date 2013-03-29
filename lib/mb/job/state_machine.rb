module MotherBrain
  class Job
    # @author Jamie Winsor <reset@riotgames.com>
    #
    # An FSM for {Job}. During each transition the Job will be instructed to save
    #
    # @api private
    class StateMachine
      include Celluloid::FSM
      include MB::Logging

      state :pending, to: [ :running, :failure ], default: true do
        log.debug { "job (#{actor.id}) transitioning to '#{state}'" }
        actor.save
      end

      state :running, to: [ :success, :failure ] do
        log.debug { "job (#{actor.id}) transitioning to '#{state}'" }
        actor.time_start = Time.now
        actor.save
      end

      state :success do
        log.debug { "job (#{actor.id}) transitioning to '#{state}'" }
        actor.time_end = Time.now
        actor.save
      end

      state :failure do
        log.debug { "job (#{actor.id}) transitioning to '#{state}'" }
        actor.time_end = Time.now
        actor.save
      end
    end
  end
end
