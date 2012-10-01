module MotherBrain
  class Plugin
    # @author Jamie Winsor <jamie@vialstudios.com>
    module Commands
      # @return [Hash]
      def commands
        @commands ||= Hash.new
      end

      def command(&block)
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
