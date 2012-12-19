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

    extend Forwardable

    def_delegator "MB::Locks.manager", :locks, :chef_locks
    def_delegator "MB::Locks.manager", :find, :find_lock

    # Attempts to create a lock. Fails if the lock already exists.
    #
    # @see ChefMutex#initialize
    #
    # @raise [MotherBrain::InvalidLockType] if the lock type is invalid
    # @raise [MotherBrain::ResourceLocked] if the lock is unobtainable
    #
    # @return [Boolean]
    def chef_lock(options = {})
      find_or_new(options).lock
    end

    # Creates a new ChefMutex on the given resource and runs the given block inside of it. The lock is
    # released when the block completes.
    #
    # @see ChefMutex#initialize
    #
    # @raise [MotherBrain::InvalidLockType] if the lock type is invalid
    # @raise [MotherBrain::ResourceLocked] if the lock is unobtainable
    #
    # @return [Boolean]
    def chef_synchronize(options = {}, &block)
      find_or_new(options).synchronize(&block)
    end

    # Attempts to unlock the lock. Fails if the lock doesn't exist, or if it is
    # held by someone else
    #
    # @see ChefMutex#initialize
    #
    # @raise [MotherBrain::InvalidLockType] if the lock type is invalid
    # @raise [MotherBrain::ResourceLocked] if the lock is owned by someone else
    def chef_unlock(options = {})
      find_or_new(options).unlock
    end

    private

      def find_or_new(*args)
        find_lock(*args) || ChefMutex.new(*args)
      end
  end
end
