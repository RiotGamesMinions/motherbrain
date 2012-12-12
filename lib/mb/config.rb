module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Config < Chozo::Config::JSON
    class << self
      def default_path
        ENV["MB_CONFIG"] || "~/.mb/config.json"
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
    end

    attribute :plugin_paths,
      default: PluginManager.default_paths,
      type: [ Set, Array ],
      required: true,
      coerce: lambda { |m| m.to_set }

    attribute 'chef.api_url',
      default: "http://localhost:8080",
      type: String,
      required: true

    attribute 'chef.api_client',
      type: String,
      required: true

    attribute 'chef.api_key',
      type: String,
      required: true

    attribute 'chef.organization',
      type: String

    attribute 'chef.validator_client',
      type: String

    attribute 'chef.validator_path',
      type: String

    attribute 'chef.bootstrap_proxy',
      type: String

    attribute 'chef.encrypted_data_bag_secret_path',
      type: String

    attribute 'ssh.user',
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

    attribute 'ssl.verify',
      default: true,
      type: Boolean

    attribute 'rest_gateway.enable',
      default: false,
      type: Boolean

    attribute 'rest_gateway.host',
      default: REST::Gateway::DEFAULT_OPTIONS[:host],
      type: String

    attribute 'rest_gateway.port',
      default: REST::Gateway::DEFAULT_OPTIONS[:port],
      type: Integer

    attribute 'rest_client.url',
      default: REST::Client::DEFAULT_URL,
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
    #     o.chef_api_url = "https://api.opscode.com"
    #     o.chef_api_client = "reset"
    #     o.chef_api_key = "/Users/reset/.chef/reset.pem"
    #     o.chef_organization = "vialstudios"
    #   end
    #
    #   config.to_ridley =>
    #   {
    #     server_url: "https://api.opscode.com",
    #     client_name: "reset",
    #     client_key: "/Users/reset/.chef/reset.pem",
    #     organization: "vialstudios"
    #   }
    #
    # @return [Hash]
    def to_ridley
      {}.tap do |ridley_opts|
        ridley_opts[:server_url] = self.chef.api_url
        ridley_opts[:client_name] = self.chef.api_client
        ridley_opts[:client_key] = self.chef.api_key
        ridley_opts[:encrypted_data_bag_secret_path] = self.chef.encrypted_data_bag_secret_path
        ridley_opts[:ssl] = {
          verify: self.ssl.verify
        }

        unless self.chef.organization.nil?
          ridley_opts[:organization] = self.chef.organization
        end
      end
    end

    def to_rest_gateway
      {}.tap do |rest_opts|
        rest_opts[:host] = self.rest_gateway.host
        rest_opts[:port] = self.rest_gateway.port
      end
    end

    def to_rest_client
      {}.tap do |opts|
        opts[:url] = self.rest_client.url
      end
    end
  end
end
