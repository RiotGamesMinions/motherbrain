module MotherBrain
  class Mutex
    DATA_BAG = "locks"

    attr_reader :chef_connection, :client_name, :name

    def initialize(name, chef_connection)
      @chef_connection = chef_connection
      @client_name = chef_connection.client_name
      @name = name
    end

    def lock
      attempt_lock
    end

    def unlock
      attempt_unlock
    end

    def attempt_lock
      current_lock = read name

      return current_lock["client_name"] == client_name if current_lock

      write name, client_name, time
    end

    def attempt_unlock
      current_lock = read name

      return unless current_lock
      return unless current_lock["client_name"] == client_name

      delete name
    end

    def data_bag
      chef_connection.data_bag
    end

    def delete
      return true unless locks

      locks.delete name
    end

    def ensure_data_bag_exists
      data_bag.create name: DATA_BAG unless locks
    end

    def locks
      result = data_bag.find DATA_BAG

      return unless result

      result.item
    end

    def read
      return unless locks

      result = locks.find name

      result.to_hash if result
    end

    def time
      Time.now
    end

    def write
      ensure_data_bag_exists

      current_lock = locks.new id: name, client_name: client_name, time: time
      current_lock.save
    end
  end
end
