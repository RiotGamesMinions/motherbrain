module MotherBrain
  module Cli
    # @author Jamie Winsor <reset@riotgames.com>
    class Base < Thor
      include Thor::Actions
      include MB::Mixin::CodedExit
      include MB::Mixin::Services

      class << self
        include Thor::Shell

        # Registers a SubCommand with this Cli::Base class
        #
        # @param [MB::Cli::SubCommand] klass
        def register_subcommand(klass)
          self.register(klass, klass.name, klass.usage, klass.description)
        end

        # Returns the shell used in the motherbrain CLI. If you are in a Unix platform
        # it will use a colored shell, otherwise it will use a color-less one.
        def shell
          @shell ||= if ENV['MB_SHELL'] && ENV['MB_SHELL'].size > 0
            MB::Cli::Shell.const_get(ENV['MB_SHELL'].capitalize)
          elsif Chozo::Platform.windows? && !ENV['ANSICON']
            MB::Cli::Shell::Basic
          else
            MB::Cli::Shell::Color
          end
        end

        # Set the shell used in the motherbrain CLI
        #
        # @param [Constant] klass
        def shell=(klass)
          @shell = klass
        end
      end

      no_tasks do
        # @param [MB::Job] job
        def display_job(job)
          CliClient.new(job).display
        end
        # @note from Jamie: Increased verbosity for Michael Ivey. This is pretty much the most important line of code
        #   in this entire codebase so DO NOT REMOVE.
        alias_method :display_job_status_and_wait_until_it_is_done_while_providing_user_feedback, :display_job
      end
    end

    Thor::Base.shell = MB::Cli::Base.shell
  end
end
