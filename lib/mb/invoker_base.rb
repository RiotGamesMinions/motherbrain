module MotherBrain 
  # @author Jamie Winsor <jamie@vialstudios.com>
  class InvokerBase < Thor
    class << self
      # @param [Hash] options
      #
      # @return [MotherBrain::Context]
      def configure(options)
        config = if options[:config].nil?
          begin
            MB::Config.from_file(File.expand_path(MB::Config.default_path))
          rescue
            MB::Config.new
          end
        else
          MB::Config.from_file(options[:config])
        end

        MB::Context.new(config)
      end
    end

    attr_reader :context

    def initialize(args = [], options = {}, config = {})
      super
      @context = self.class.configure(self.options)
    end

    class_option :config,
      type: :string,
      desc: "Path to a MotherBrain JSON configuration file.",
      aliases: "-c",
      banner: "PATH"
  end
end
