module MotherBrain 
  # @author Jamie Winsor <jamie@vialstudios.com>
  class InvokerBase < Thor
    class << self
      def configure(opts)
        if opts[:config].nil?
          begin
            MB::Config.from_file(File.expand_path(MB::Config.default_path))
          rescue
            MB::Config.new
          end
        else
          MB::Config.from_file(opts[:config])
        end
      end
    end

    attr_reader :config

    def initialize(args = [], options = {}, config = {})
      super
      @config = self.class.configure(self.options)
    end

    class_option :config,
      type: :string,
      desc: "Path to a MotherBrain JSON configuration file.",
      aliases: "-c",
      banner: "PATH"

    no_tasks do
      def chef_conn
        @chef_conn ||= Ridley.connection(config.to_ridley)
      end
    end
  end
end
