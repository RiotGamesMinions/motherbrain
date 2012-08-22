require 'mb/cli_base'

module MotherBrain
  module Pvpnet
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Commands < CliBase
      namespace :pvpnet

      desc "start ENV", "start a pvpnet cluster"
      def start(name)
        cluster = Pvpnet::Cluster.new(name, ridley)
        MB.ui.say cluster.start
      end

      desc "stop ENV", "stop a pvpnet cluster"
      def stop(name)
        cluster = Pvpnet::Cluster.new(name, ridley)
        MB.ui.say cluster.stop
      end

      desc "status ENV", "display the status of a pvpnet cluster"
      def status(name)        
        cluster = Pvpnet::Cluster.new(name, ridley)
        MB.ui.say cluster.status
      end

      desc "update ENV, VERSION", "update a pvpnet cluster to a new version"
      def update(name, version)
        cluster = Pvpnet::Cluster.new(name, ridley)
        MB.ui.say cluster.update(version)
      end

      desc "version", "Display version information"
      def version
        MB.ui.say "MotherBrain: PvPnet (#{MB::Pvpnet::VERSION})"
      end
    end

    MB::Cli.register Commands, 'pvpnet', 'pvpnet [COMMAND]', 'Cluster controls for pvpnet platform core'
  end
end

Dir["#{File.dirname(__FILE__)}/commands/*.rb"].sort.each do |path|
  require "mb-pvpnet/commands/#{File.basename(path, '.rb')}"
end
