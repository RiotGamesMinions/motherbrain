module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class CleanRoomBase
    extend Forwardable
    include Chozo::VariaModel

    # @param [MB::Context] context
    # @param [MB::ContextualModel] binding
    #
    # @return [MB::ContextualModel]
    def initialize(context, binding, &block)
      @context = context
      @binding = binding

      instance_eval(&block)
      binding
    end

    private

      attr_reader :context
      attr_reader :binding

      def_delegator :context, :config
      def_delegator :context, :chef_conn
      def_delegator :context, :environment
  end
end
