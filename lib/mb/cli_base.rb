require 'motherbrain'
require 'thor'
require 'thor/group'

module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class CliBase < Thor
    def initialize(*)
      super
      @options = options.dup # unfreeze frozen options Hash from Thor
      @options[:config] ? load_config! : load_config
    end

    attr_reader :config

    class_option :config,
      type: :string,
      desc: "Path to a MotherBrain JSON configuration file.",
      aliases: "-c",
      banner: "PATH"

    no_tasks do
      def chef_conn
        @chef_conn ||= Ridley.connection(config.to_ridley)
      end
      
      def config_path
        File.expand_path(options[:config] || MB::Config.default_path)
      end
    end

    private

      def load_config
        @config = begin
          load_config!
        rescue Chozo::Errors::ConfigNotFound
          MB::Config.new
        end
      end

      def load_config!
        @config = MB::Config.from_file(config_path)
      end
  end
end
