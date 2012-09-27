module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Command
    extend Forwardable

    attr_reader :name

    def_delegator :plugin, :component

    def initialize(plugin, name, &block)
      @plugin = plugin
      @name = name

      instance_eval(&block) if block_given?
    end

    # @return [Symbol]
    def id
      self.name.to_sym
    end

    private

      attr_reader :plugin
  end
end
