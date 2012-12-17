module MotherBrain
  # @author Justin Campbell <justin@justincampbell.me>
  # @author Jamie Winsor <jamie@vialstudios.com>
  #
  # Allows for MotherBrain clients to lock a chef resource. A mutex is created
  # with a type and name. Sending #lock to the mutex will then store a data bag
  # item with mutex, the requestor's client_name, and the current time. An
  # attempt to lock an already-locked mutex will fail if the lock is owned by
  # someone else, or succeed if the lock is owned by the current user.
  #
  # @example Creating a mutex and obtaining a lock
  #
  #   mutex = ChefMutex.new(chef_environment: "my_environment")
  #
  #   mutex.lock # => true
  #   # do stuff
  #   mutex.unlock # => true
  #
  # @example Running a block within an obtained lock
  #
  #   mutex = ChefMutex.new(chef_environment: "my_environment")
  #
  #   mutex.synchronize do
  #     # do stuff
  #   end
  #
  class ChefMutex
    include Celluloid
    include Celluloid::Notifications

    extend Forwardable

    DATA_BAG = "_motherbrain_locks_".freeze

    LOCK_TYPES = [
      :chef_environment
    ]

    attr_reader :type
    attr_reader :name

    attr_accessor :force
    attr_accessor :unlock_on_failure

    # @option options [#to_s] :chef_environment
    #   The name of the environment to lock
    # @option options [Boolean] :force (false)
    #   Force the lock to be written, even if it already exists.
    # @option options [Boolean] :unlock_on_failure (true)
    #   If false and the block raises an error, the lock will persist.
    def initialize(options = {})
      options = options.reverse_merge(
        force: false,
        unlock_on_failure: true
      )

      type, name = options.find { |key, value| LOCK_TYPES.include? key }

      @type              = type
      @name              = name
      @force             = options[:force]
      @unlock_on_failure = options[:unlock_on_failure]
    end

    # @return [String]
    def data_bag_id
      result = to_s.dup

      result.downcase!
      result.gsub! /[^\w]+/, "-" # dasherize
      result.gsub! /^-+|-+$/, "" # remove dashes from beginning/end

      result
    end

    # @return [String]
    def to_s
      "#{type}:#{name}"
    end

    # Attempts to create a lock. Fails if the lock already exists.
    #
    # @return [Boolean]
    def lock
      return true if externally_testing?

      unless type
        raise InvalidLockType, "Must pass a valid lock type (#{LOCK_TYPES})"
      end

      MB.log.info "Locking #{to_s}"

      attempt_lock
    end

    # Obtains a lock, runs the block, and releases the lock when the block
    # completes. Raises a ResourceLocked error if the lock was unobtainable.
    # If the block raises an error, the resource is unlocked, unless
    # unlock_on_failure: true is passed in to the option hash.
    #
    # @raise [MotherBrain::ResourceLocked] if the lock is unobtainable
    #
    # @return [Boolean]
    def synchronize
      unless lock
        current_lock = read

        raise ResourceLocked,
          "Resource #{current_lock['id']} locked by #{current_lock['client_name']} since #{current_lock['time']}\n"
      end

      yield

      unlock
    rescue ResourceLocked
      raise
    rescue
      unlock if self.unlock_on_failure
      raise
    end

    # Attempts to unlock the lock. Fails if the lock doesn't exist, or if it is
    # held by someone else
    #
    # @return [Boolean]
    def unlock
      return true if externally_testing?

      MB.log.info "Unlocking #{to_s}"

      attempt_unlock
    end

    private

      # @return [Boolean]
      def attempt_lock
        unless self.force
          current_lock = read

          return current_lock["client_name"] == client_name if current_lock
        end

        write
      end

      # @return [Boolean]
      def attempt_unlock
        unless self.force
          current_lock = read

          return unless current_lock
          return unless current_lock["client_name"] == client_name
        end

        delete
      end

      # @return [String]
      def client_name
        Application.ridley.client_name
      end

      # @return [Ridley::ChainLink]
      def data_bag
        Application.ridley.data_bag
      end

      # Delete the lock from the data bag.
      #
      # @return [Boolean]
      def delete
        return true unless locks

        result = locks.delete(data_bag_id)

        Locks.manager.unregister(Actor.current)

        result
      rescue
        Locks.manager.register(Actor.current)
      end

      # Create our data bag if it doesn't already exist
      def ensure_data_bag_exists
        data_bag.create(name: DATA_BAG) unless locks
      end

      # To prevent tests on code that use locks from actually locking anything,
      # we provide the #externally_testing? method that reflects the status, and
      # we can stub it to return false if we actually want to test the locking
      # code.
      #
      # @return [Boolean]
      def externally_testing?
        ENV['RUBY_ENV'] == 'test'
      end

      # @return [Ridley::DBIChainLink] if the data bag exists
      # @return [nil] if it does not
      def locks
        result = data_bag.find(DATA_BAG)

        return unless result

        result.item
      end

      # Read the lock from the data bag.
      #
      # @return [Hash] if the lock exists
      # @return [nil] if it does not
      def read
        return unless locks

        result = locks.find(data_bag_id)

        result.to_hash if result
      end

      # Write the lock to the data bag.
      #
      # @return [Boolean]
      def write
        ensure_data_bag_exists

        result = locks.new(
          id: data_bag_id,
          type: type,
          name: name,
          client_name: client_name,
          time: Time.now
        ).save

        Locks.manager.register(Actor.current)

        result
      rescue
        Locks.manager.unregister(Actor.current)
      end
  end
end
