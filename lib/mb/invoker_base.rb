module MotherBrain 
  # @author Jamie Winsor <jamie@vialstudios.com>
  class InvokerBase < Thor
    class << self
      # @param [Hash] options
      #
      # @return [MotherBrain::Context]
      def configure(options)
        config = if options[:config].nil?
          MB::Config.from_file(File.expand_path(MB::Config.default_path))
        else
          MB::Config.from_file(options[:config])
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

    attr_reader :context

    def initialize(args = [], options = {}, config = {})
      super
      unless ["configure", "help", "version"].include? config[:current_task].try(:name)
        @context = self.class.configure(self.options)
      end
    end

    class_option :config,
      type: :string,
      desc: "Path to a MotherBrain JSON configuration file.",
      aliases: "-c",
      banner: "PATH"
  end
end
