module MotherBrain
  module Locks
    # @author Jamie Winsor <jamie@vialstudios.com>
    #
    # A registry of locks obtained against resources on a Chef Server
    class Manager
      include Celluloid
      include MB::Logging

      # @return [Set<ChefMutex>]
      attr_reader :locks

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

      def finalize
        log.info { "Lock Manager stopping..." }
      end

      # Unlock an environment
      #
      # @param [String] environment
      def unlock(environment)
        job = Job.new(:unlock)

        chef_mutex = ChefMutex.new(
          chef_environment: environment,
          force: true,
          job: job,
          report_job_status: true
        )

        chef_mutex.async.unlock

        job.ticket
      end
    end
  end
end
