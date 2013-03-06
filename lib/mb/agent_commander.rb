module MotherBrain
  # @author Jamie WInsor <reset@riotgames.com>
  class AgentCommander
    class << self
      # @raise [Celluloid::DeadActorError] if the environment manager has not been started
      #
      # @return [Celluloid::Actor(EnvironmentManager)]
      def instance
        MB::Application[:agent_commander] or raise Celluloid::DeadActorError, "agent commander not running"
      end
    end

    include Celluloid

    # @param [String] node
    #
    # @raise [MB::AgentNotFound]
    def find(node)
      unless DCell::Node[node]
        abort MB::AgentNotFound.new("unable to locate the registered agent: '#{node}'")
      end
    end

    # @param [MB::Job] job
    # @param [String] node
    # @param [Hash] chef_attributes (nil)
    #   any additional chef attributes to set for this particular Chef run. These attributes
    #   will be sent to Chef::Client.new
    # @param [Hash] options (Hash.new)
    #   options to pass to Chef::Client.new
    def run_chef(job, node, chef_attributes = nil, options = {})
      find(node)[:chef_client].run(job, chef_attributes, options)
    end
  end
end
