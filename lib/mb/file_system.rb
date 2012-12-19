module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module FileSystem
    autoload :Tempfile, 'mb/file_system/tempfile'

    class << self
      # @return [Pathname]
      def root
        Pathname.new(default_root_path)
      end

      # @return [Pathname]
      def tmp
        root.join("tmp")
      end

      # @return [Pathname]
      def plugins
        root.join("plugins")
      end

      # @return [Pathname]
      def logs
        root.join("logs")
      end

      # @return [String]
      def tmpdir
        FileUtils.mkdir_p(tmp)
        Dir.mktmpdir(nil, tmp)
      end

      private

        def default_root_path
          File.expand_path(ENV["MOTHERBRAIN_PATH"] || "~/.mb")
        end
    end
  end
end
