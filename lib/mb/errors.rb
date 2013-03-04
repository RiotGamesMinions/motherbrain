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

    alias_method :mesage, :to_s

    def to_hash
      {
        code: status_code,
        message: to_s
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

  class InternalError < MBError; status_code(99); end
  class ArgumentError < InternalError; end
  class AbstractFunction < InternalError; end
  class ReservedGearKeyword < InternalError; end
  class DuplicateGearKeyword < InternalError; end
  class InvalidProvisionerClass < InternalError; end
  class ProvisionerRegistrationError < InternalError; end
  class ProvisionerNotRegistered < InternalError; end
  class RemoteScriptError < InternalError; end
  class RemoteCommandError < InternalError; end

  class PluginSyntaxError < MBError; status_code(100); end
  class DuplicateGroup < PluginSyntaxError; end
  class DuplicateChefAttribute < PluginSyntaxError; end
  class ValidationFailed < PluginSyntaxError; end
  class DuplicateAction < PluginSyntaxError; end
  class DuplicateGear < PluginSyntaxError; end
  class ActionNotFound < PluginSyntaxError; end
  class GroupNotFound < PluginSyntaxError; end

  class PluginLoadError < MBError; status_code(101); end
  class InvalidCookbookMetadata < PluginLoadError
    attr_reader :errors
    
    def initialize(errors)
      @errors = errors
    end
  end

  class ChefRunnerError < MBError; status_code(102); end
  class NoValueForAddressAttribute < ChefRunnerError; end

  class ActionNotSupported < MBError; status_code(103); end

  class GearError < MBError; status_code(104); end

  class ChefRunFailure < MBError
    status_code(105)

    def initialize(errors)
      @errors = errors
    end
  end
  class ChefTestRunFailure < ChefRunFailure; end

  class JobNotFound < MBError
    status_code(106)

    attr_reader :job_id

    def initialize(id)
      @job_id = id
    end

    def to_s
      "No job with ID: '#{job_id}' found"
    end
  end

  class PluginNotFound < MBError
    status_code(107)

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

  class NoBootstrapRoutine < MBError; status_code(108); end
  class PluginDownloadError < MBError; status_code(109); end

  class CommandNotFound < MBError
    status_code(110)

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
    status_code(111)

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

    def to_s
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
  class ResourceLocked < MBError; status_code(18); end
  class InvalidProvisionManifest < MBError; status_code(19); end
  class ManifestNotFound < MBError; status_code(20); end
  class InvalidManifest < MBError; status_code(21); end

  class UnexpectedProvisionCount < MBError
    status_code(20)

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

  class ComponentNotVersioned < MBError
    status_code(22)

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

  class InvalidLockType < MBError; status_code(23); end
  class BootstrapError < MBError; status_code(24); end
end
