module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class PluginInvoker < InvokerBase
    class << self
      # Return the plugin used to generate the anonymous CLI class
      #
      # @return [MotherBrain::Plugin]
      attr_reader :plugin

      # @param [MotherBrain::Plugin] plugin
      #
      # @return [Class]
      def fabricate(plugin)
        klass = Class.new(self)
        klass.namespace(plugin.name)
        klass.set_plugin(plugin)

        klass
      end

      protected

        # Set the plugin used to generate the anonymous CLI class. Can be
        # retrieved later by calling MyClass::plugin.
        #
        # @param [MotherBrain::Plugin] plugin
        def set_plugin(plugin)
          @plugin = plugin
        end
    end

    desc "version", "Display plugin version"
    def version
      MB.ui.say self.class.plugin.version
    end
  end
end
