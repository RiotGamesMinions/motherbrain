require 'logger'

module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module Logging
    autoload :BasicFormat, 'mb/logging/basic_format'

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
        level = Logger::WARN
        level = Logger::INFO if options[:verbose]
        level = Logger::DEBUG if options[:debug]

        location = options[:logfile]

        if location
          location = location.constantize if location.start_with? "STD"
        else
          location = STDOUT
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
