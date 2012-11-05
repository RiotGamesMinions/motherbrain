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
  class ArgumentError < InternalError; end
  class AbstractFunction < InternalError; end
  class ReservedGearKeyword < InternalError; end
  class DuplicateGearKeyword < InternalError; end

  class PluginSyntaxError < MBError; status_code(100); end
  class DuplicateGroup < PluginSyntaxError; end
  class DuplicateChefAttribute < PluginSyntaxError; end
  class ValidationFailed < PluginSyntaxError; end
  class DuplicateAction < PluginSyntaxError; end
  class DuplicateGear < PluginSyntaxError; end
  class CommandNotFound < PluginSyntaxError; end
  class ComponentNotFound < PluginSyntaxError; end
  class ActionNotFound < PluginSyntaxError; end
  class GroupNotFound < PluginSyntaxError; end

  class PluginLoadError < MBError; status_code(101); end
  class AlreadyLoaded < PluginLoadError; end

  class ChefRunnerError < MBError; status_code(102); end
  class NoValueForAddressAttribute < ChefRunnerError; end

  class ActionNotSupported < MBError; status_code(103); end

  class ChefRunFailure < MBError
    status_code(103)

    def initialize(errors)
      @errors = errors
    end
  end
  class ChefTestRunFailure < ChefRunFailure; end

  class ClusterBusy < MBError; status_code(10); end
  class ClusterNotFound < MBError; status_code(11); end
  class EnvironmentNotFound < MBError; status_code(12); end

  class InvalidConfig < MBError
    status_code(13)

    # @return [ActiveModel::Errors]
    attr_reader :errors

    # @param [ActiveModel::Errors] errors
    def initialize(errors)
      @errors = errors
    end

    def message
      msg = errors.collect do |key, messages|
        "* #{key}: #{messages.join(', ')}"
      end
      msg.unshift "-----"
      msg.unshift "Invalid Configuration File"
      msg.join("\n")
    end
  end

  class ConfigNotFound < MBError; status_code(14); end
  class ConfigExists < MBError; status_code(15); end
  class ChefConnectionError < MBError; status_code(16); end
  class InvalidBootstrapManifest < MBError; status_code(17); end
end
