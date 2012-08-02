module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class MBError < StandardError
    class << self
      # @param [Integer] code
      def status_code(code)
        define_method(:status_code) { code }
        define_singleton_method(:status_code) { code }
      end
    end

    alias_method :message, :to_s
  end

  class InternalError < MBError; status_code(99); end
  class ClusterBusy < MBError; status_code(10); end
  class ClusterNotFound < MBError; status_code(11); end
  class EnvironmentNotFound < MBError; status_code(12); end
  class InvalidConfig < MBError; status_code(13); end
  class ConfigNotFound < MBError; status_code(14); end
  class ConfigExists < MBError; status_code(15); end
end
