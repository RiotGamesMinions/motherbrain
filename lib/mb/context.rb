module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Context < OpenStruct
    # @return [MotherBrain::Config]
    attr_reader :config

    # @param [MotherBrain::Config] config
    # @param [Hash] attributes
    def initialize(config, attributes = {})
      @config = config
      super(attributes)
    end

    # @return [Ridley::Connection]
    def chef_conn
      @chef_conn ||= Ridley.connection(config.to_ridley.merge(ssl: { verify: false }))
    end
  end
end
