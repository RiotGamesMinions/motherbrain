module MotherBrain
  class Plugin
    # @author Jamie Winsor <jamie@vialstudios.com>
    module Commands
      # @return [Hash]
      def commands
        @commands ||= Hash.new
      end

      # @param [#to_sym] name
      def command(name, &block)
        add_command name, Proc.new(&block)
      end

      private

        # @param [#to_sym] name
        # @param [Command] command
        def add_command(name, command)
          self.commands[name] = command
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
