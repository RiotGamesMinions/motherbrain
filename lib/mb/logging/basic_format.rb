module MotherBrain
  module Logging
    class BasicFormat < Logger::Formatter
      def call(severity, datetime, progname, msg)
        if match = msg.match(/NODE\[.+?\]/)
          "#{msg.lines.to_a.map { |line| line.start_with?(match.to_s) ? line : "#{match} #{line}" }.join}"
        else
          "[#{datetime.utc.iso8601}] PID[#{Process.pid}] TID[#{Thread.current.object_id.to_s(36)}] #{severity}: #{msg}\n"
        end
      end
    end
  end
end
