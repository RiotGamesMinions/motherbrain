module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class ContextualModel
    extend Forwardable
    
    include Mixin::SimpleAttributes

    # @param [MB::Context] context
    def initialize(context)
      @context = context
    end

    private

      attr_reader :context

      def_delegator :context, :config
      def_delegator :context, :chef_conn
      def_delegator :context, :environment
  end
end
