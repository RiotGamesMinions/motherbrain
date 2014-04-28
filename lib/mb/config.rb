require 'buff/config/json'

module MotherBrain
  class Config < Buff::Config::JSON
    class << self
      # The default location for motherbrain's config file
      #
      # @return [String]
      def default_path
        FileSystem.root.join("config.json").to_s
      end

      # @see Buff::Config::JSON.from_json
      #
      # @raise [MB::ConfigNotFound]
      def from_file(*args)
        super
      rescue Buff::Errors::ConfigNotFound => ex
        raise MB::ConfigNotFound, ex
      rescue Buff::Errors::InvalidConfig => ex
        raise MB::InvalidConfig.new(syntax_error: [ex.message])
      end

      def from_hash(hash)
        super
      rescue Buff::Errors::ConfigNotFound => ex
        raise MB::ConfigNotFound, ex
      rescue Buff::Errors::InvalidConfig => ex
        raise MB::InvalidConfig.new(syntax_error: [ex.message])
      end

      # @raise [Celluloid::DeadActorError] if ConfigManager has not been started
      #
      # @return [Celluloid::Actor(ConfigManager)]
      def manager
        ConfigManager.instance
      end

      # Validate the given config
      #
      # @param [MB::Config] config
      #
      # @raise [MB::InvalidConfig] if the given configuration is invalid
      def validate!(config)
        unless config.valid?
          raise InvalidConfig.new(config.errors)
        end
      end

      def chef_config
        MB::Chef::Config.new.parse
      end
    end

    attribute 'berkshelf.path',
      default: MB::Berkshelf.default_path,
      type: String,
      required: true

    attribute 'chef.api_url',
      default: (ENV['CHEF_API_URL'] || chef_config[:chef_server_url]),
      type: String,
      required: true

    attribute 'chef.api_client',
      default: chef_config[:node_name],
      type: String,
      required: true

    attribute 'chef.api_key',
      default: chef_config[:client_key],
      type: String,
      required: true

    attribute 'chef.validator_client',
      default: chef_config[:validation_client_name],
      type: String

    attribute 'chef.validator_path',
      default: chef_config[:validation_key],
      type: String

    attribute 'chef.bootstrap_proxy',
      type: String

    attribute 'chef.encrypted_data_bag_secret_path',
      type: String

    attribute 'ssh.user',
      default: ENV['USER'],
      type: String

    attribute 'ssh.password',
      type: String

    attribute 'ssh.keys',
      type: [ Set, Array ],
      coerce: lambda { |m| m.to_set }

    attribute 'ssh.sudo',
      default: true,
      type: Boolean

    attribute 'ssh.timeout',
      default: 10.0,
      type: [ Integer, Float ]

    attribute 'ssh.verbose',
      type: String

    attribute 'winrm.user',
      default: ENV['USER'],
      type: String

    attribute 'winrm.password',
      type: String

    attribute 'winrm.port',
      default: 5985,
      type: Integer

    attribute 'ssl.verify',
      default: true,
      type: Boolean

    attribute 'ridley.connector_pool_size',
      default: 25,
      type: Integer

    attribute 'log.level',
      default: 'INFO',
      type: String,
      coerce: lambda { |m|
        m = m.is_a?(String) ? m.upcase : m
        case m
        when Logger::DEBUG
          'DEBUG'
        when Logger::INFO
          'INFO'
        when Logger::WARN
          'WARN'
        when Logger::ERROR
          'ERROR'
        when Logger::FATAL
          'FATAL'
        when 'DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL'
          m
        else; nil
        end
      }

    attribute 'log.location',
      default: 'STDOUT',
      type: String,
      coerce: lambda { |m|
        o = m
        m = m.is_a?(String) ? m.upcase : m
        case m
        when STDOUT; 'STDOUT'
        when STDERR; 'STDERR'
        when 'STDOUT', 'STDERR'; m
        else; o
        end
      }

    attribute 'server.daemonize',
      default: false,
      type: Boolean

    attribute 'server.pid',
      default: "/var/run/motherbrain/mb.pid",
      type: String

    attribute 'rest_gateway.enable',
      default: false,
      type: Boolean

    attribute 'rest_gateway.host',
      default: RestGateway::DEFAULT_OPTIONS[:host],
      type: String

    attribute 'rest_gateway.port',
      default: RestGateway::DEFAULT_OPTIONS[:port],
      type: Integer

    # Enables the plugin manager to automatically populate its set of plugins
    # from cookbooks present on the remote Chef server that contain plugins
    attribute 'plugin_manager.eager_loading',
      default: false,
      type: Boolean

    # How long the plugin manager will wait before polling the Chef Server to eagerly
    # load any new plugins
    attribute 'plugin_manager.eager_load_interval',
      default: 300, # 5 minutes
      type: Integer

    # Allows the plugin manager load it's plugins asynchronously in the background during startup
    attribute 'plugin_manager.async_loading',
      default: false,
      type: Boolean

    attribute 'ef.api_url',
      type: String

    attribute 'ef.api_key',
      type: String

    attribute 'aws.access_key',
      type: String,
      default: ENV['AWS_ACCESS_KEY']

    attribute 'aws.secret_key',
      type: String,
      default: ENV['AWS_SECRET_KEY']

    attribute 'aws.endpoint',
      type: String,
      default: ENV['EC2_URL']

    attribute 'bootstrap.default_template',
      type: String

    # Validate the instantiated config
    #
    # @raise [MB::InvalidConfig] if the given configuration is invalid
    def validate!
      self.class.validate!(self)
    end

    # Returns a connection hash for Ridley from the instance's attributes
    #
    # @example
    #   config = MB::Config.new.tap do |o|
    #     o.chef_api_url = "https://api.opscode.com/organizations/vialstudios"
    #     o.chef_api_client = "reset"
    #     o.chef_api_key = "/Users/reset/.chef/reset.pem"
    #   end
    #
    #   config.to_ridley =>
    #   {
    #     server_url: "https://api.opscode.com/organizations/vialstudios",
    #     client_name: "reset",
    #     client_key: "/Users/reset/.chef/reset.pem",
    #     validator_client: nil,
    #     validator_path: nil
    #   }
    #
    # @return [Hash]
    def to_ridley
      {}.tap do |ridley_opts|
        ridley_opts[:server_url] = self.chef.api_url
        ridley_opts[:client_name] = self.chef.api_client
        ridley_opts[:client_key] = self.chef.api_key
        ridley_opts[:encrypted_data_bag_secret_path] = self.chef.encrypted_data_bag_secret_path
        ridley_opts[:validator_path] = self.chef.validator_path
        ridley_opts[:validator_client] = self.chef.validator_client
        ridley_opts[:ssh] = self.ssh
        ridley_opts[:winrm] = self.winrm
        ridley_opts[:ssl] = {
          verify: self.ssl.verify
        }

        ridley_opts[:connector_pool_size] = if ENV.has_key?('MB_CONNECTOR_POOL')
                                              ENV['MB_CONNECTOR_POOL'].to_i
                                            else
                                              ridley.connector_pool_size
                                            end
        ridley_opts[:ssh][:verbose] = ridley_opts[:ssh][:verbose].to_sym if ridley_opts[:ssh][:verbose]
      end
    end

    def to_rest_gateway
      {}.tap do |rest_opts|
        rest_opts[:host] = self.rest_gateway.host
        rest_opts[:port] = self.rest_gateway.port
      end
    end

    def to_logger
      {}.tap do |opts|
        opts[:level] = self.log.level
        opts[:location] = self.log.location
      end
    end
  end
end
