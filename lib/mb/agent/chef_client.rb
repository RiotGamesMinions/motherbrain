require 'chef/client'

module MotherBrain::Agent
  # @author Jamie Winsor <reset@riotgames.com>
  class ChefClient
    include Celluloid
    include MB::Logging

    # @param [MB::Job] job
    # @param [Hash] chef_attributes (nil)
    #   any additional chef attributes to set for this particular Chef run. These attributes
    #   will be sent to Chef::Client.new
    # @param [Hash] options (Hash.new)
    #   options to pass to Chef::Client.new
    #
    # @return [Boolean]
    def run(job, chef_attributes = nil, options = {})
      client = ::Chef::Client.new(chef_attributes, options)
      client.events.register(JobNotifier.new(job))

      result = client.run
      client = nil
      result
    rescue Exception => ex
      log.fatal { "Chef encountered an error: #{ex.class} - #{ex.message}" }
      log.debug { ex.backtrace.join("\n ") }
      abort(ex)
    end
  end
end
