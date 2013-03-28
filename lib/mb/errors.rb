module MotherBrain
  # @author Jamie Winsor <reset@riotgames.com>
  class MBError < StandardError
    class << self
      # @param [Integer] code
      #
      # @return [Integer]
      def exit_code(code = 1)
        return @exit_code if @exit_code
        @exit_code = code
      end

      # @param [Integer] code
      #
      # @return [Integer]
      def error_code(code = -1)
        return @error_code if @error_code
        @error_code = code
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

  class InternalError < MBError; exit_code(99); end
  class ArgumentError < InternalError; end
  class AbstractFunction < InternalError; end
  class ReservedGearKeyword < InternalError; end
  class DuplicateGearKeyword < InternalError; end
  class InvalidProvisionerClass < InternalError; end
  class ProvisionerRegistrationError < InternalError; end
  class ProvisionerNotRegistered < InternalError; end
  class RemoteScriptError < InternalError; end
  class RemoteCommandError < InternalError; end
  class RemoteFileCopyError < InternalError; end

  class PluginSyntaxError < MBError; exit_code(100); end
  class DuplicateGroup < PluginSyntaxError; end
  class DuplicateChefAttribute < PluginSyntaxError; end
  class ValidationFailed < PluginSyntaxError; end
  class DuplicateAction < PluginSyntaxError; end
  class DuplicateGear < PluginSyntaxError; end
  class ActionNotFound < PluginSyntaxError; end
  class GroupNotFound < PluginSyntaxError; end

  class PluginLoadError < MBError; exit_code(101); end
  class InvalidCookbookMetadata < PluginLoadError
    attr_reader :errors
    
    def initialize(errors)
      @errors = errors
    end
  end

  class ChefRunnerError < MBError; exit_code(102); end
  class NoValueForAddressAttribute < ChefRunnerError; end

  class ActionNotSupported < MBError; exit_code(103); end

  class GearError < MBError; exit_code(104); end

  class ChefRunFailure < MBError
    exit_code(105)

    def initialize(errors)
      @errors = errors
    end
  end
  class ChefTestRunFailure < ChefRunFailure; end

  class JobNotFound < MBError
    exit_code(106)

    attr_reader :job_id

    def initialize(id)
      @job_id = id
    end

    def to_s
      "No job with ID: '#{job_id}' found"
    end
  end

  class PluginNotFound < MBError
    exit_code(107)

    attr_reader :name
    attr_reader :version

    def initialize(name, version = nil)
      @name    = name
      @version = version
    end

    def to_s
      msg = "No plugin named '#{name}'"
      msg << " of version (#{version})" unless version.nil?
      msg << " found"
    end
  end

  class NoBootstrapRoutine < MBError; exit_code(108); end
  class PluginDownloadError < MBError; exit_code(109); end

  class CommandNotFound < MBError
    exit_code(110)

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

    def to_s
      "#{parent.class} '#{parent}' does not have the command: '#{name}'"
    end
  end

  class ComponentNotFound < MBError
    exit_code(111)

    attr_reader :name
    attr_reader :plugin

    # @param [String] name
    # @param [MB::Plugin] plugin
    def initialize(name, plugin)
      @name   = name
      @plugin = plugin
    end

    def to_s
      "Plugin #{plugin} does not have the component: '#{name}'"
    end
  end

  class ClusterBusy < MBError; exit_code(10); end
  class ClusterNotFound < MBError; exit_code(11); end
  class EnvironmentNotFound < MBError; exit_code(12); end

  class InvalidConfig < MBError
    exit_code(13)

    # @return [ActiveModel::Errors]
    attr_reader :errors

    # @param [ActiveModel::Errors] errors
    def initialize(errors)
      @errors = errors
    end

    def to_s
      msg = errors.collect do |key, messages|
        "* #{key}: #{messages.join(', ')}"
      end
      msg.unshift "-----"
      msg.unshift "Invalid Configuration File"
      msg.join("\n")
    end
  end

  class ConfigNotFound < MBError; exit_code(14); end
  class ConfigExists < MBError; exit_code(15); end
  class ChefConnectionError < MBError; exit_code(16); end
  class InvalidBootstrapManifest < MBError; exit_code(17); end
  class ResourceLocked < MBError; exit_code(18); end
  class InvalidProvisionManifest < MBError; exit_code(19); end
  class ManifestNotFound < MBError; exit_code(20); end
  class InvalidManifest < MBError; exit_code(21); end

  class ComponentNotVersioned < MBError
    exit_code(22)

    attr_reader :component_name

    def initialize(component_name)
      @component_name = component_name
    end

    def to_s
      [
        "Component '#{component_name}' is not versioned",
        "You can version components with:",
        "  versioned # defaults to \"#{component_name}.version\"",
        "  versioned_with \"custom.version.attribute\""
      ].join "\n"
    end
  end

  class InvalidLockType < MBError; exit_code(23); end
  class BootstrapError < MBError; exit_code(24); end
  class GroupBootstrapError < BootstrapError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
    end

    def to_s
      group_err_count = errors.collect { |group, errors| "#{group} (#{errors.length} errors)" }.join(', ')
      "there were failures while bootstrapping some groups: #{group_err_count}"
    end
  end
  class CookbookConstraintNotSatisfied < BootstrapError; end
  class InvalidAttributesFile < BootstrapError; end

  class ProvisionError < MBError; exit_code(20); end
  class UnexpectedProvisionCount < ProvisionError
    attr_reader :expected
    attr_reader :got

    def initialize(expected, got)
      @expected = expected
      @got      = got
    end

    def to_s
      "Expected '#{expected}' nodes to be provisioned but got: '#{got}'"
    end
  end
end
