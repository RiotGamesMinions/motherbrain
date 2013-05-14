module MotherBrain
  # @author Jamie Winsor <reset@riotgames.com>
  #
  # A registry of locks obtained against resources on a Chef Server
  class LockManager
    class << self
      # @raise [Celluloid::DeadActorError] if lock manager has not been started
      #
      # @return [Celluloid::Actor(LockManager)]
      def instance
        MB::Application[:lock_manager] or raise Celluloid::DeadActorError, "lock manager not running"
      end
    end

    include Celluloid
    include MB::Logging

    # @return [Set<ChefMutex>]
    attr_reader :locks

    finalizer do
      log.info { "Lock Manager stopping..." }
    end

    def initialize
      log.info { "Lock Manager starting..." }
      @locks = Set.new
    end

    # Find a lock of the given name in the list of registered locks
    #
    # @see ChefMutex#initialize
    #
    # @return [ChefMutex, nil]
    def find(options)
      type, name = options.to_a.flatten

      locks.find { |mutex|
        mutex.type == type &&
        mutex.name == name
      }
    end

    # Register the given lock
    #
    # @param [ChefMutex] mutex
    def register(mutex)
      locks.add(mutex)
    end

    def reset
      self.locks.clear
    end

    # Unregister the given lock
    #
    # @param [ChefMutex] mutex
    def unregister(mutex)
      locks.delete(mutex)
    end

    # Asynchronously lock an environment
    #
    # @param [String] environment
    #
    # @return [MB::JobRecord]
    def async_lock(environment)
      job = Job.new(:lock)
      async(:lock, job, environment)
      job.ticket
    end

    # Lock an environment
    #
    # @param [MB::Job] job
    # @param [String] environment
    #
    # @return [Boolean]
    def lock(job, environment)
      ChefMutex.new(
        chef_environment: environment,
        force: true,
        job: job,
        report_job_status: true
      ).lock
    end

    # Asynchronously unlock an environment
    #
    # @param [String] environment
    #
    # @return [MB::JobRecord]
    def async_unlock(environment)
      job = Job.new(:unlock)
      async(:unlock, job, environment)
      job.ticket
    end

    # Unlock an environment
    #
    # @param [MB::Job] job
    # @param [String] environment
    #
    # @return [Boolean]
    def unlock(job, environment)
      ChefMutex.new(
        chef_environment: environment,
        force: true,
        job: job,
        report_job_status: true
      ).unlock
    end
  end
end
