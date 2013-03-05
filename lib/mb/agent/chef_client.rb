require 'chef'
require 'chef/client'

module MotherBrain::Agent
  # @author Jamie Winsor <reset@riotgames.com>
  class ChefClient
    include Celluloid

    def initialize(options = {})
      @client = ::Chef::Client.new(nil, options)
    end

    def run
      client.run
    end

    private

      attr_reader :client
  end
end
