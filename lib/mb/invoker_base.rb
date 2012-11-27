module MotherBrain 
  # @author Jamie Winsor <jamie@vialstudios.com>
  class InvokerBase < Thor
    class << self
      # @param [Hash] options
      #
      # @return [MotherBrain::Context]
      def configure(options)
        file = options[:config] || File.expand_path(MB::Config.default_path)

        begin
          config = MB::Config.from_file file
        rescue Chozo::Errors::ConfigNotFound => e
          raise e.class.new "#{e.message}\nCreate one with `mb configure`"
        end

        validate_config(config)
        MB::Context.new(config)
      end

      private

        # @raise [InvalidConfig] if configuration is invalid
        #
        # @return [Boolean]
        def validate_config(config)
          unless config.valid?
            raise InvalidConfig.new(config.errors)
          end

          true
        end
    end

    NOCONFIG_TASKS = [
      "configure",
      "help",
      "version"
    ].freeze

    attr_reader :context

    def initialize(args = [], options = {}, config = {})
      super
      unless NOCONFIG_TASKS.include? config[:current_task].try(:name)
        @context = self.class.configure(self.options)
      end

      MB.log.level = Logger::INFO if @options[:verbose]
      MB.log.level = Logger::DEBUG if @options[:debug]
    end

    class_option :config,
      type: :string,
      desc: "Path to a MotherBrain JSON configuration file.",
      aliases: "-c",
      banner: "PATH"
    class_option :verbose,
      type: :boolean,
      desc: "Increase verbosity of output.",
      default: false,
      aliases: "-v"
    class_option :debug,
      type: :boolean,
      desc: "Output all log messages.",
      default: false,
      aliases: "-d"
  end
end
