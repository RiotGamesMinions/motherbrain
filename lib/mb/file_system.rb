require 'tmpdir'

module MotherBrain
  # @author Jamie Winsor <reset@riotgames.com>
  module FileSystem
    autoload :Tempfile, 'mb/file_system/tempfile'

    class << self
      # Create the directory structure for motherbrain
      def init
        FileUtils.mkdir_p(root)
        FileUtils.mkdir_p(logs)
        FileUtils.mkdir_p(tmp)
        FileUtils.mkdir_p(templates)
      end

      # @return [Pathname]
      def logs
        root.join("logs")
      end

      # @return [Pathname]
      def root
        Pathname.new(default_root_path)
      end

      # @return [Pathname]
      def tmp
        root.join("tmp")
      end

      # @return [Pathname]
      def templates
        root.join("templates")
      end

      # Create a temporary directory in the tmp directory of the motherbrain
      # file system
      #
      # @param [String] prefix (nil)
      #   a prefix suffix to attach to name of the generated directory
      #
      # @return [String]
      def tmpdir(prefix = nil)
        Dir.mktmpdir(prefix, tmp)
      end

      private

        def default_root_path
          File.expand_path(ENV["MOTHERBRAIN_PATH"] || "~/.mb")
        end
    end
  end
end
