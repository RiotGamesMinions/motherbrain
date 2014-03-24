module MotherBrain
  # This module contains integration code for Berkshelf into motherbrain
  module Berkshelf
    class << self
      # An array of Pathnames representing cookbooks in the Berkshelf
      #
      # @option options [Boolean] :with_plugin
      #   only return cookbooks that contain a plugin
      #
      # @return [Array<Pathname>]
      def cookbooks(options = {})
        cookbooks = cookbooks_path.children

        if options[:with_plugin]
          cookbooks.select! { |cb_path| Dir.has_mb_plugin?(cb_path) }
        end

        cookbooks
      end

      # Location of the cookbooks directory in the Berkshelf
      #
      # @return [Pathname]
      def cookbooks_path
        path.join('cookbooks')
      end

      # The default location of the Berkshelf. This is in your user directory
      # unless explicitly specified by the environment variable 'BERKSHELF_PATH'
      #
      # @return [String]
      def default_path
        ENV["BERKSHELF_PATH"] || File.expand_path("~/.berkshelf")
      end

      # Create the directory structure for the Berkshelf
      def init
        FileUtils.mkdir_p(path)
        FileUtils.mkdir_p(cookbooks_path)
      end

      # The location of the Berkshelf
      #
      # @return [Pathname]
      def path
        Pathname.new(Application.config.berkshelf.path || default_path)
      end
    end

    # A wrapper around the berkshelf's Berkshelf::Lockfile
    class Lockfile
      include MB::Logging

      BERKSFILE_LOCK = 'Berksfile.lock'.freeze

      class << self
        def from_path(root_path)
          new(File.join(root_path, BERKSFILE_LOCK))
        end
      end

      attr_reader :berksfile_lock

      def initialize(berksfile_lock_path)
        @berksfile_lock = ::Berkshelf::Lockfile.from_file(berksfile_lock_path)
      end

      # Return a hash of all of the cookbook versions found in the Berksfile.lock
      # The key is the name of the cookbook and the value is the version as a
      # String. If there is no lockfile an empty hash is returned.
      #
      # @return [Hash]
      def locked_versions
        berksfile_lock.graph.locks.inject({}) do |hash, (name, dependency)|
          hash[name] = dependency.locked_version.to_s
          hash
        end
      end
    end
  end
end
