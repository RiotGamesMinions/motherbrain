module MotherBrain
  module PluginDSL
    # @author Jamie Winsor <jamie@vialstudios.com>
    module Commands
      # @return [Hash]
      def commands
        @commands ||= Hash.new
      end

      # @raise [PluginSyntaxError] if no block is given
      def command(&block)
        unless block_given?
          raise PluginSyntaxError, "Command definition missing a required block"
        end

        add_command Command.new(&block)
      end

      private

        # @param [Command] command
        def add_command(command)
          self.commands[command.name] = command
        end

        # @param [#to_sym] name
        #
        # @return [Plugin::Command]
        def get_command(name)
          self.commands.fetch(name.to_sym, nil)
        end
    end
  end
end
