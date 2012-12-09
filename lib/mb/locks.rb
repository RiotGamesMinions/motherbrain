module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module Locks
    autoload :Manager, 'mb/locks/manager'
    
    class << self
      # @return [Locks::Manager]
      def manager
        Celluloid::Actor[:lock_manager] or raise Celluloid::DeadActorError, "lock manager actor not running"
      end
    end

    # @return [Set<ChefMutex>]
    def chef_locks
      MB::Locks.manager.locks
    end

    # @param [#to_s] name
    #
    # @return [ChefMutex, nil]
    def find_lock(name)
      MB::Locks.manager.find(name)
    end

    # Attempts to create a lock. Fails if the lock already exists.
    #
    # @param [#to_s] name
    # @option options [Boolean] :force
    #   Force the lock to be written, even if it already exists.
    # @option options [Boolean] :unlock_on_failure
    #   Defaults to true. If false and the block raises an error, the lock will
    #   persist.
    #
    # @return [Boolean]
    def chef_lock(name, options = {})
      find_or_new(name, options).lock
    end

    # Creates a new ChefMutex on the given resource and runs the given block inside of it. The lock is
    # released when the block completes.
    #
    # @param [#to_s] name
    # @option options [Boolean] :force
    #   Force the lock to be written, even if it already exists.
    # @option options [Boolean] :unlock_on_failure
    #   Defaults to true. If false and the block raises an error, the lock will
    #   persist.
    #
    # @raise [MotherBrain::ResourceLocked] if the lock is unobtainable
    #
    # @return [Boolean]
    def chef_synchronize(name, options = {}, &block)
      find_or_new(name, options).synchronize(&block)
    end

    # Attempts to unlock the lock. Fails if the lock doesn't exist, or if it is
    # held by someone else
    #
    # @param [#to_s] name
    # @option options [Boolean] :force
    #   Force the lock to be written, even if it already exists.
    # @option options [Boolean] :unlock_on_failure
    #   Defaults to true. If false and the block raises an error, the lock will
    #   persist.
    def chef_unlock(name, options = {})
      find_or_new(name, options).unlock
    end

    private

      def find_or_new(name, *args)
        find_lock(name) || ChefMutex.new(name, *args)
      end
  end
end
