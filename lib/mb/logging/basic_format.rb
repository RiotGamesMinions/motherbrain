module MotherBrain
  module Logging
    class BasicFormat < Logger::Formatter
      def call(severity, datetime, progname, msg)
        "[#{datetime.utc.iso8601}] PID[#{Process.pid}] TID[#{Thread.current.object_id.to_s(36)}] #{severity}: #{msg}\n"
      end
    end
  end
end
