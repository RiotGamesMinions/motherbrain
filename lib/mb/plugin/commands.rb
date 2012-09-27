module MotherBrain
  class Plugin
    # @author Jamie Winsor <jamie@vialstudios.com>
    module Commands
      # @return [Hash]
      def commands
        @commands ||= Hash.new
      end

      def command(name, &block)
        add_command name, Proc.new(&block)
      end

      private

        # @param [Command] command
        def add_command(name, command)
          self.commands[name] = command
        end

        # @param [Command] command
        def get_command(name)
          self.commands.fetch(name, nil)
        end
    end
  end
end
