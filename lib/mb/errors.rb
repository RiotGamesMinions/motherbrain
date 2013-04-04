module MotherBrain
  module Errors
    class << self
      # @return [Hash]
      def error_codes
        @error_codes ||= Hash.new
      end

      # @param [MBError] klass
      #
      # @raise [RuntimeError]
      def register(klass)
        if error_codes.has_key?(klass.error_code)
          msg = "Unable to register exception #{klass}. The error_code #{klass.error_code} is already"
          msg << " in use by #{error_codes[klass.error_code]}."
          raise RuntimeError, msg
        end

        error_codes[klass.error_code] = klass
      end

      # @param [MBError] klass
      def unregister(klass)
        error_codes.delete(klass.error_code)
      end
    end
  end

  # @author Jamie Winsor <reset@riotgames.com>
  class MBError < StandardError
    DEFAULT_EXIT_CODE = 1

    class << self
      # @param [Integer] code
      #
      # @return [Integer]
      def exit_code(code = DEFAULT_EXIT_CODE)
        @exit_code ||= code
      end

      # @param [Integer] code
      #
      # @return [Integer]
      def error_code(code = -1)
        return @error_code if @error_code
        @error_code = code
        Errors.register(self)
        @error_code
      end
    end

    # @param [String] message
    def initialize(message = nil)
      super(message)
      @message = message
    end

    # @return [Integer]
    def exit_code
      self.class.exit_code
    end

    # @return [Integer]
    def error_code
      self.class.error_code
    end

    # @return [String]
    def message
      @message || self.class.to_s
    end

    def to_s
      "[err_code]: #{error_code} [message]: #{message}"
    end

    def to_hash
      {
        code: error_code,
        message: message
      }
    end

    # @param [Hash] options
    #   a set of options to pass to MultiJson.encode
    #
    # @return [String]
    def to_json(options = {})
      MultiJson.encode(self.to_hash, options)
    end
  end

  # Internal errors
  class InternalError < MBError
    exit_code(99)
    error_code(1000)
  end

  class ArgumentError < InternalError
    error_code(1001)
  end

  class AbstractFunction < InternalError
    error_code(1002)
  end

  class ReservedGearKeyword < InternalError
    error_code(1003)
  end

  class DuplicateGearKeyword < InternalError
    error_code(1004)
  end

  class InvalidProvisionerClass < InternalError
    error_code(1005)
  end

  class ProvisionerRegistrationError < InternalError
    error_code(1006)
  end

  class ProvisionerNotRegistered < InternalError
    error_code(1007)
  end

  class RemoteScriptError < InternalError
    error_code(1008)
  end

  class RemoteCommandError < InternalError
    error_code(1009)
  end

  class RemoteFileCopyError < InternalError
    error_code(1010)
  end

  class ActionNotSupported < InternalError
    exit_code(103)
    error_code(1011)
  end

  # Plugin loading errors
  class PluginSyntaxError < MBError
    exit_code(100)
    error_code(2000)
  end

  class DuplicateGroup < PluginSyntaxError
    error_code(2001)
  end

  class DuplicateChefAttribute < PluginSyntaxError
    error_code(2002)
  end

  class ValidationFailed < PluginSyntaxError
    error_code(2003)
  end

  class DuplicateAction < PluginSyntaxError
    error_code(2004)
  end

  class DuplicateGear < PluginSyntaxError
    error_code(2005)
  end

  class ActionNotFound < PluginSyntaxError
    error_code(2006)
  end

  class GroupNotFound < PluginSyntaxError
    error_code(2007)
  end

  class PluginLoadError < MBError
    exit_code(101)
    error_code(2008)
  end

  class InvalidCookbookMetadata < PluginLoadError
    error_code(2009)
    attr_reader :errors

    def initialize(errors)
      @errors = errors
    end
  end

  # Standard errors
  class ChefRunnerError < MBError
    exit_code(102)
    error_code(3000)
  end

  class NoValueForAddressAttribute < ChefRunnerError
    error_code(3001)
  end

  class JobNotFound < MBError
    exit_code(106)
    error_code(3002)

    attr_reader :job_id

    def initialize(id)
      @job_id = id
    end

    def message
      "No job with ID: '#{job_id}' found"
    end
  end

  class PluginNotFound < MBError
    exit_code(107)
    error_code(3003)

    attr_reader :name
    attr_reader :version

    def initialize(name, version = nil)
      @name    = name
      @version = version
    end

    def message
      msg = "No plugin named '#{name}'"
      msg << " of version (#{version})" unless version.nil?
      msg << " found"
    end
  end

  class NoBootstrapRoutine < MBError
    exit_code(108)
    error_code(3004)
  end

  class PluginDownloadError < MBError
    exit_code(109)
    error_code(3005)
  end

  class CommandNotFound < MBError
    exit_code(110)
    error_code(3006)

    attr_reader :name
    attr_reader :parent

    # @param [String] name
    #   name of the command that was not found
    # @param [MB::Plugin, MB::Component] parent
    #   plugin that we searched for the command on
    def initialize(name, parent)
      @name   = name
      @parent = parent
    end

    def message
      "#{parent.class} '#{parent}' does not have the command: '#{name}'"
    end
  end

  class ComponentNotFound < MBError
    exit_code(111)
    error_code(3007)

    attr_reader :name
    attr_reader :plugin

    # @param [String] name
    # @param [MB::Plugin] plugin
    def initialize(name, plugin)
      @name   = name
      @plugin = plugin
    end

    def message
      "Plugin #{plugin} does not have the component: '#{name}'"
    end
  end

  class EnvironmentNotFound < MBError
    exit_code(12)
    error_code(3008)

    attr_reader :name

    def initialize(name)
      @name = name
    end

    def message
      "An environment named '#{name}' could not be found"
    end
  end

  class InvalidConfig < MBError
    exit_code(13)
    error_code(3009)

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

  class ConfigNotFound < MBError
    exit_code(14)
    error_code(3010)
  end

  class ConfigExists < MBError
    exit_code(15)
    error_code(3011)
  end

  class ChefConnectionError < MBError
    exit_code(16)
    error_code(3012)
  end

  class InvalidBootstrapManifest < MBError
    exit_code(17)
    error_code(3013)
  end

  class ResourceLocked < MBError
    exit_code(18)
    error_code(3014)
  end

  class InvalidProvisionManifest < MBError
    exit_code(19)
    error_code(3015)
  end

  class ManifestNotFound < MBError
    exit_code(20)
    error_code(3016)
  end

  class InvalidManifest < MBError
    exit_code(21)
    error_code(3017)
  end

  class ComponentNotVersioned < MBError
    exit_code(22)
    error_code(3018)

    attr_reader :component_name

    def initialize(component_name)
      @component_name = component_name
    end

    def message
      [
        "Component '#{component_name}' is not versioned",
        "You can version components with:",
        "  versioned # defaults to \"#{component_name}.version\"",
        "  versioned_with \"custom.version.attribute\""
      ].join "\n"
    end
  end

  class InvalidLockType < MBError
    exit_code(23)
    error_code(3019)
  end

  class GearError < MBError
    exit_code(104)
    error_code(3020)
  end

  class ChefRunFailure < MBError
    exit_code(105)
    error_code(3021)

    def initialize(errors)
      @errors = errors
    end
  end

  class ChefTestRunFailure < MBError
    error_code(3022)
  end

  # Bootstrap errors
  class BootstrapError < MBError
    exit_code(24)
    error_code(4000)
  end

  class GroupBootstrapError < BootstrapError
    error_code(4001)
    attr_reader :errors

    def initialize(errors)
      @errors = errors
    end

    def message
      group_err_count = errors.collect { |group, errors| "#{group} (#{errors.length} errors)" }.join(', ')
      "there were failures while bootstrapping some groups: #{group_err_count}"
    end
  end

  class CookbookConstraintNotSatisfied < BootstrapError
    error_code(4002)
  end

  class InvalidAttributesFile < BootstrapError
    error_code(4003)
  end

  # Provision errors
  class ProvisionError < MBError
    exit_code(20)
    error_code(5000)
  end

  class UnexpectedProvisionCount < ProvisionError
    error_code(5001)

    attr_reader :expected
    attr_reader :got

    def initialize(expected, got)
      @expected = expected
      @got      = got
    end

    def message
      "Expected '#{expected}' nodes to be provisioned but got: '#{got}'"
    end
  end
end
