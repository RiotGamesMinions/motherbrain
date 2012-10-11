module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Config
    class << self
      def default_path
        ENV["MB_CONFIG"] || "~/.mb/config.json"
      end
    end

    include Chozo::Config::JSON

    attribute :chef_api_url, default: "http://localhost:8080"
    validates_presence_of :chef_api_url
    validates_format_of :chef_api_url, with: URI::regexp(%w(http https))

    attribute :chef_api_client
    validates_presence_of :chef_api_client

    attribute :chef_api_key
    validates_presence_of :chef_api_key

    attribute :chef_organization
    
    attribute :nexus_api_url
    validates_presence_of :nexus_api_url
    validates_format_of :nexus_api_url, with: URI::regexp(%w(http https))

    attribute :nexus_repository
    validates_presence_of :nexus_repository

    attribute :nexus_username
    validates_presence_of :nexus_username

    attribute :nexus_password
    validates_presence_of :nexus_password

    attribute :plugin_paths, default: PluginLoader.default_paths

    attribute :ssh_user
    validates_presence_of :ssh_user

    attribute :ssh_password
    attribute :ssh_key

    validates_with ConfigValidator

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
