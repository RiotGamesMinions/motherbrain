require 'logger'

module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module Logging
    autoload :BasicFormat, 'mb/logging/basic_format'

    DEFAULTS = {
      level: Logger::INFO,
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
        @preserved_options = nil
      end

      # @option [Boolean] debug
      # @option [String] logfile
      #
      # @return [Logger]
      def setup(options = {})
        options = options.keep_if { |key, value| value }
        options = preserve(options).reverse_merge(DEFAULTS)

        level    = options[:level]
        location = options[:location]

        if %w[STDERR STDOUT].include? location
          location = location.constantize
        end

        @logger = Logger.new(location).tap do |log|
          log.level = level
          log.formatter = BasicFormat.new
        end

        Ridley.logger = @logger
        Celluloid.logger = @logger

        @logger
      end

      # @param [Logger, nil] obj
      #
      # @return [Logger]
      def set_logger(obj)
        @logger = (obj.nil? ? Logger.new('/dev/null') : obj)
      end

      private

      # Stores and returns an updated hash, so that #setup can be called
      # multiple times
      #
      # @param [Hash] options
      #
      # @return [Hash]
      def preserve(options)
        @preserved_options ||= Hash.new
        @preserved_options.reverse_merge! options
      end
    end

    # @return [Logger]
    def logger
      MB::Logging.logger
    end
    alias_method :log, :logger
  end
end
