require 'logger'

module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module Logging
    autoload :BasicFormat, 'mb/logging/basic_format'
    include Logger::Severity

    class << self
      include Logger::Severity

      # @return [Logger]
      def logger
        @logger ||= setup
      end

      # @return [nil]
      def reset
        @logger = nil
        @preserved_options = nil
      end

      # @option options [String, Integer] :level (INFO)
      # @option options [String, IO] :location
      #
      # @return [Logger]
      def setup(options = {})
        options = options.keep_if { |key, value| value }
        options = preserve(options).reverse_merge(
          level: INFO,
          location: FileSystem.logs.join('application.log')
        )

        level    = options[:level].is_a?(String) ? options[:level].upcase : options[:level]
        location = options[:location]

        if %w[DEBUG INFO WARN ERROR FATAL].include?(level)
          level = const_get(level)
        end

        if %w[STDERR STDOUT].include?(location)
          location = location.constantize
        end

        unless [STDERR, STDOUT].include?(location)
          setup_logdir(location)
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

        def setup_logdir(location)
          FileUtils.mkdir_p(File.dirname(location), mode: 0755)
        end
    end

    # @return [Logger]
    def logger
      MB::Logging.logger
    end
    alias_method :log, :logger
  end
end
