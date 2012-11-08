module MotherBrain
  # @author Justin Campbell <justin@justincampbell.me>
  #
  # Allows for MotherBrain clients to lock a chef resource
  class ChefMutex
    DATA_BAG = "locks"

    attr_reader :chef_connection, :client_name, :name

    # @param [#to_s] name
    # @param [Ridley::Connection] chef_connection
    def initialize(name, chef_connection)
      @chef_connection = chef_connection
      @client_name = chef_connection.client_name
      @name = name
    end

    # Attempts to create a lock. Fails if the lock already exists.
    #
    # @return [Boolean]
    def lock
      attempt_lock
    end

    # Attempts to unlock the lock. Fails if the lock doesn't exist, or if it is
    # held by someone else
    #
    # @return [Boolean]
    def unlock
      attempt_unlock
    end

    private

      # @return [Boolean]
      def attempt_lock
        current_lock = read

        return current_lock["client_name"] == client_name if current_lock

        write
      end

      # @return [Boolean]
      def attempt_unlock
        current_lock = read

        return unless current_lock
        return unless current_lock["client_name"] == client_name

        delete
      end

      # @return [Ridley::ChainLink]
      def data_bag
        chef_connection.data_bag
      end

      # Delete the lock from the data bag.
      #
      # @return [Boolean]
      def delete
        return true unless locks

        locks.delete name
      end

      # Create our data bag if it doesn't already exist
      def ensure_data_bag_exists
        data_bag.create name: DATA_BAG unless locks
      end

      # @return [Ridley::DBIChainLink] if the data bag exists
      # @return [nil] if it does not
      def locks
        result = data_bag.find DATA_BAG

        return unless result

        result.item
      end

      # Read the lock from the data bag.
      #
      # @return [Hash] if the lock exists
      # @return [nil] if it does not
      def read
        return unless locks

        result = locks.find name

        result.to_hash if result
      end

      # Write the lock to the data bag.
      #
      # @return [Boolean]
      def write
        ensure_data_bag_exists

        current_lock = locks.new id: name, client_name: client_name, time: Time.now
        current_lock.save
      end
  end
end
