require 'chef/client'

module MotherBrain::Agent
  # @author Jamie Winsor <reset@riotgames.com>
  class ChefClient
    include Celluloid

    # @return [Hash]
    #   options that will be sent to wrapped instances of {Chef::Client}
    attr_reader :options
    # @return [Hash]
    #   a Hash containing any chef attributes which should be set for any Chef run executed
    #   by this agent
    attr_reader :default_chef_attributes

    # @param [Hash] chef_attributes
    #   additional attributes to set for each Chef client run
    # @param [Hash] options
    #   options to pass to {Chef::Client.new}
    def initialize(chef_attributes = nil, options = {})
      @default_chef_attributes = chef_attributes || Hash.new
      @options                 = options
    end

    # @param [MB::Job] job
    # @param [Hash] chef_attributes
    #   any additional chef attributes to set for this particular Chef run. These attributes
    #   will be merged over any {#default_chef_attributes} defined when ChefClient was iniitalized.
    #
    # @return [Boolean]
    def run(job, chef_attributes = {})
      chef_attributes = default_chef_attributes.reverse_merge(chef_attributes)

      client = ::Chef::Client.new(chef_attributes, options)
      client.events.register(JobNotifier.new(job))

      result = client.run
      client = nil
      result
    end
  end
end
