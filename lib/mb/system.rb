require 'ohai'
require 'rbconfig'

module MotherBrain
  # @author Jamie Winsor <reset@riotgames.com>
  module System
    class << self
      def node_name
        @node_name ||= begin
          ohai = ::Ohai::System.new
          ohai.require_plugin("#{os}/hostname")
          ohai[:fqdn] || ohai[:hostname]
        end
      end

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
  end
end
