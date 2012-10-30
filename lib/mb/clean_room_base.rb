module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class CleanRoomBase < ContextualModel
    # @param [MB::Context] context
    # @param [MB::ContextualModel] binding
    #
    # @return [MB::ContextualModel]
    def initialize(context, binding, &block)
      super(context)
      @binding = binding

      instance_eval(&block)
      binding
    end

    private

      attr_reader :binding
  end
end
