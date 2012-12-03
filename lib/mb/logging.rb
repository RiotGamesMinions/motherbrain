require 'logger'

module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module Logging
    autoload :BasicFormat, 'mb/logging/basic_format'

    DEFAULTS = {
      level: Logger::WARN,
      location: STDOUT
    }

    class << self
      # @return [Logger]
      def logger
        @logger ||= setup
      end

      # @return [nil]
      def reset
        @logger = nil
      end

      # @option [Boolean] verbose
      # @option [Boolean] debug
      # @option [String] logfile
      #
      # @return [Logger]
      def setup(options = {})
        options.reverse_merge! DEFAULTS

        level    = options[:level]
        location = options[:location]

        if %w[STDERR STDOUT].include? location
          location = location.constantize
        end

        @logger = Logger.new(location).tap do |log|
          log.level = level
          log.formatter = BasicFormat.new
        end
      end

      # @param [Logger, nil] obj
      #
      # @return [Logger]
      def set_logger(obj)
        @logger = (obj.nil? ? Logger.new('/dev/null') : obj)
      end
    end

    # @return [Logger]
    def logger
      MB::Logging.logger
    end
    alias_method :log, :logger
  end
end
