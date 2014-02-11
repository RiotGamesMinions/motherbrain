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

    attr_reader :host

    def initialize(message, host=nil)
      super(message)
      @host = host if host
    end

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

  class ConfigOptionMissing < MBError
    exit_code(24)
    error_code(3026)
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

  class RequiredFileNotFound < MBError
    error_code(3023)

    attr_reader :filename
    attr_reader :required_for

    def initialize(filename, options = {})
      @filename = filename
      @required_for = options[:required_for]
    end

    def message
      msg = "#{@filename} does not exist, but is required"
      msg += " for #{@required_for}" if @required_for
      msg += "."
      msg
    end
  end

  class BootstrapTemplateNotFound < MBError
    exit_code(106)
    error_code(3024)
  end

  class InvalidEnvironmentJson < MBError
    error_code(3025)

    def initialize(path, json_error=nil)
      @path = path
    end

    def message
      msg = "Environment JSON contained in #{path} is invalid."
      msg << "\n#{json_error.message}" if json_error and json_error.responds_to?(:message)
      msg
    end
  end

  class FileNotFound < MBError
    error_code(3027)

    def initialize(path)
      @path = path
    end

    def message
      "File does not exist: #{path}"
    end
  end

  class InvalidDynamicService < MBError
    error_code(3028)

    def initialize(component, service_name)
      @component = component
      @service_name = service_name
    end

    def message
      msg = "Both component: #{@component} and service name: #{@service_name} are required."
      msg << "\nFormat should be in a dotted form - COMPONENT.SERVICE"
    end
  end

  # Bootstrap errors
  class BootstrapError < MBError
    exit_code(24)
    error_code(4000)
  end

  class GroupBootstrapError < BootstrapError
    error_code(4001)

    # @return [Array<String>]
    attr_reader :groups
    # @return [Hash]
    attr_reader :host_errors

    # @param [Hash] host_errors
    #
    #  "cloud-3.riotgames.com" => {
    #    groups: ["database_slave::default"],
    #    result: {
    #      status: :ok
    #      message: ""
    #      bootstrap_type: :partial
    #    }
    #  }
    def initialize(host_errors)
      @groups      = Set.new
      @host_errors = Hash.new

      host_errors.each do |host, host_info|
        @host_errors[host] = host_info
        host_info[:groups].each { |group| @groups.add(group) }
      end
    end

    def message
      err = ""
      groups.each do |group|
        err << "failure bootstrapping group #{group}\n"
        host_errors.each do |host, host_info|
          if host_info[:groups].include?(group)
            err << "  * #{host} #{host_info[:result]}\n"
          end
        end
        err << "\n"
      end
      err
    end
  end

  class CookbookConstraintNotSatisfied < BootstrapError
    error_code(4002)
  end

  class InvalidAttributesFile < BootstrapError
    error_code(4003)
  end

  class ValidatorPemNotFound < RequiredFileNotFound
    error_code(4004)

    def initialize(filename, options = { required_for: 'bootstrap' })
      super
    end
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

  class ProvisionerNotStarted < ProvisionError
    error_code(5002)
    attr_reader :provisioner_id

    def initialize(provisioner_id)
      @provisioner_id = provisioner_id
    end

    def message
      "No provisioner registered or started that matches the ID: '#{provisioner_id}'.\n"
      "Registered provisioners are: #{MB::Provisioner.all.map(&:provisioner_id).join(', ')}"
    end
  end

  # Chef errors
  class ChefError < MBError
    exit_code(26)
    error_code(9000)
  end

  class NodeNotFound < ChefError
    error_code(9001)

    attr_reader :name

    def initialize(name)
      @name = name
    end

    def message
      "A node named '#{name}' could not be found on the Chef server"
    end
  end

  class EnvironmentNotFound < MBError
    exit_code(12)
    error_code(9002)

    attr_reader :name

    def initialize(name)
      @name = name
    end

    def message
      "An environment named '#{name}' could not be found"
    end
  end

  class DataBagNotFound < ChefError
    error_code(9003)

    attr_reader :name

    def initialize(name)
      @name = name
    end

    def message
      "A Data Bag named '#{name}' could not be found"
    end
  end

  class DataBagItemNotFound < ChefError
    error_code(9004)

    attr_reader :data_bag_name
    attr_reader :item_name

    def initialize(data_bag_name, item_name)
      @data_bag_name = data_bag_name
      @item_name     = item_name
    end

    def message
      "An item named '#{item_name}' was not found in the '#{data_bag_name}' data bag."
    end
  end

  class PrerequisiteNotInstalled < MBError
    error_code(9005)
  end

  class EnvironmentExists < ChefError
    error_code(9006)

    attr_reader :name

    def initialize(name)
      @name = name
    end

    def message
      "An environment named '#{name}' already exists in the Chef Server."
    end
  end
end
