module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Config < Chozo::Config::JSON
    class << self
      def default_path
        ENV["MB_CONFIG"] || "~/.mb/config.json"
      end
    end

    attribute :chef_api_url,
      default: "http://localhost:8080",
      type: String,
      required: true

    attribute :chef_api_client,
      type: String,
      required: true

    attribute :chef_api_key,
      type: String,
      required: true

    attribute :chef_organization,
      type: String

    attribute :chef_validator_client,
      type: String

    attribute :chef_validator_path,
      type: String

    attribute :chef_bootstrap_proxy,
      type: String

    attribute :chef_encrypted_data_bag_secret_path,
      type: String

    attribute :plugin_paths,
      default: PluginLoader.default_paths,
      type: [ Array, Set ],
      required: true

    attribute :ssh_user,
      type: String

    attribute :ssh_password,
      type: String

    attribute :ssh_keys,
      type: [ Array, Set ]

    attribute :ssh_sudo,
      default: true,
      type: Boolean

    attribute :ssh_timeout,
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
        ridley_opts[:server_url] = self.chef_api_url
        ridley_opts[:client_name] = self.chef_api_client
        ridley_opts[:client_key] = self.chef_api_key
        ridley_opts[:encrypted_data_bag_secret_path] = self.chef_encrypted_data_bag_secret_path
        ridley_opts[:ssl] = self.ssl

        unless self.chef_organization.nil?
          ridley_opts[:organization] = self.chef_organization
        end
      end
    end
  end
end
