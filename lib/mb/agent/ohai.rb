require 'rbconfig'

module MotherBrain::Agent
  # @author Jamie Winsor <reset@riotgames.com>
  class Ohai < ::Ohai::System
    class << self
      # The string representation of the executing operating system used by the
      # Ohai plugin system
      #
      # @return [String]
      def os
        case ::RbConfig::CONFIG['host_os']
        when /aix(.+)$/; "aix"
        when /darwin(.+)$/; "darwin"
        when /hpux(.+)$/; "hpux"
        when /linux/; "linux"
        when /freebsd(.+)$/; "freebsd"
        when /openbsd(.+)$/; "openbsd"
        when /netbsd(.*)$/; "netbsd"
        when /solaris2/; "solaris2"
        when /mswin|mingw32|windows/; "windows"
        else
          ::RbConfig::CONFIG['host_os']
        end
      end
    end

    include Celluloid
  end
end
