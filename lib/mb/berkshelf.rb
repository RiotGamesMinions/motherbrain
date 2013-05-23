module MotherBrain
  # @author Jamie Winsor <reset@riotgames.com>
  #
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
  end
end
