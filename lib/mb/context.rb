module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Context < OpenStruct
    extend Forwardable

    # @return [MotherBrain::Config]
    attr_reader :config

    # @return [Ridley::Connection]
    def_delegator :config, :to_ridley, :chef_conn

    # @param [MotherBrain::Config] config
    # @param [Hash] attributes
    def initialize(config, attributes = {})
      @config = config
      super(attributes)
    end
  end
end
