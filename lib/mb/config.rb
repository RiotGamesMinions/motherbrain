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

    attribute :plugin_paths,
      default: PluginLoader.default_paths,
      type: [ Array, Set ],
      required: true

    attribute :ssh_user,
      type: String

    attribute :ssh_password,
      type: String

    attribute :ssh_key,
      type: String

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

        unless self.chef_organization.nil?
          ridley_opts[:organization] = self.chef_organization
        end
      end
    end
  end
end
