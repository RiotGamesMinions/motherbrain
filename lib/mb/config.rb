module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Config
    class << self
      def default_path
        ENV["MB_CONFIG"] || "~/.mb/config.json"
      end
    end

    include Mixed::JSONConfig

    attr_accessor :filepath

    attribute :chef_api_url, default: "http://localhost:8080"
    validates_presence_of :chef_api_url
    validates_format_of :chef_api_url, with: URI::regexp(%w(http https))

    attribute :chef_api_client
    validates_presence_of :chef_api_client

    attribute :chef_api_key
    validates_presence_of :chef_api_key
    
    attribute :nexus_api_url
    validates_presence_of :nexus_api_url
    validates_format_of :nexus_api_url, with: URI::regexp(%w(http https))

    attribute :nexus_repository
    validates_presence_of :nexus_repository

    attribute :nexus_username
    validates_presence_of :nexus_username

    attribute :nexus_password
    validates_presence_of :nexus_password

    def initialize(filepath = nil, attributes = {})
      @filepath = filepath
      self.attributes = attributes
    end

    def save
      FileUtils.mkdir_p(File.dirname(filepath))
      File.open(filepath, 'w+') do |f|
        f.puts JSON.pretty_generate(self.as_json)
      end
    end
  end
end
