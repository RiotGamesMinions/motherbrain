module MotherBrain
  module Logging
    class MultiLogger
      attr_accessor :formatter, :level
      attr_reader :dev

      def initialize(dev)
        @dev = dev
      end

      def dev_logger
        @dev_logger ||= begin
          log = Logger.new dev
          log.level = level
          log.formatter = formatter
          log
        end
      end

      def file_logger
        @file_logger ||= begin
          log = Logger.new "~/.mb/motherbrain.log"
          log.level = Logger::INFO
          log.formatter = formatter
          log
        end
      end

      %w[debug error fatal info log unknown].each do |method_name|
        define_method method_name do |*args|
          dev_logger.send method_name, *args
          file_logger.send method_name, *args
        end
      end
    end
  end
end
