require 'pry'
require 'pry/repl'

module MotherBrain
  class Console < Pry::REPL
    class << self
      # @option options [Object] :target ({MB::Application})
      #   The initial context for this session.
      # @option options [Array<Proc>] :prompt ({Console.default_prompt})
      #   The array of Procs to use for prompts.
      # @option options [#readline] :input
      #   The object to use for input.
      # @option options [#puts] :output
      #   The object to use for output.
      # @option options [Pry::CommandBase] :commands
      #   The object to use for commands.
      # @option options [Hash] :hooks
      #   The defined hook Procs.
      # @option options [Proc] :print
      #   The Proc to use for printing return values.
      # @option options [Boolean] :quiet
      #   Omit the `whereami` banner when starting.
      # @option options [Array<String>] :backtrace
      #   The backtrace of the session's `binding.pry` line, if applicable.
      def start(options = {})
        options = options.reverse_merge(target: MB::Application, prompt: method(:default_prompt))
        super(options)
      end

      def default_prompt(target, nest_level, pry)
        "mb(#{Pry.view_clip(target.class)}: #{Pry.view_clip(target)}):[#{nest_level}] >> "
      end
    end
  end
end
