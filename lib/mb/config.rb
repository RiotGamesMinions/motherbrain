module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Config < Chozo::Config::JSON
    class << self
      def default_path
        ENV["MB_CONFIG"] || "~/.mb/config.json"
      end

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
      default: PluginLoader.default_paths,
      type: [ Array, Set ],
      required: true

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
      type: [ Array, Set ]

    attribute 'ssh.sudo',
      default: true,
      type: Boolean

    attribute 'ssh.timeout',
      default: 10.0,
      type: [ Integer, Float ]

    attribute 'ssl.verify',
      default: true,
      type: Boolean

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
        ridley_opts[:ssl] = self.ssl

        unless self.chef.organization.nil?
          ridley_opts[:organization] = self.chef.organization
        end
      end
    end
  end
end
