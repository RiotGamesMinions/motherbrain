module MotherBrain
  module Logging
    class BasicFormat < Logger::Formatter
      def call(severity, datetime, progname, msg)
        message = msg.to_s

        if match = message.match(/NODE\[.+?\]/)
          format_matched_lines match, message
        else
          "[#{datetime.utc.iso8601}] #{severity}: #{message}\n"
        end
      end

      private

      def format_matched_lines(match, message)
        lines = message.lines.to_a

        lines.map! do |line|
          if line.start_with? match.to_s
            line
          else
            "#{match} #{line}"
          end
        end

        lines.join("\n") << "\n"
      end
    end
  end
end
