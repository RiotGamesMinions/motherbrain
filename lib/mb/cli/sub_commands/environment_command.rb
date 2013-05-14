module MotherBrain
  module Cli
    # @author Jamie Winsor <reset@riotgames.com>
    class EnvironmentCommand < Cli::Base
      method_option :force,
        type: :boolean,
        default: false,
        desc: "perform the configuration even if the environment is locked"
      desc "configure ENVIRONMENT FILE", "configure a Chef environment"
      def configure(environment, attributes_file)
        attributes_file = File.expand_path(attributes_file)

        begin
          content = File.read(attributes_file)
        rescue Errno::ENOENT
          MB.ui.say "No attributes file found at: '#{attributes_file}'"
          exit(1)
        end

        begin
          attributes = MultiJson.decode(content)
        rescue MultiJson::DecodeError => ex
          MB.ui.say "Error decoding JSON from: '#{attributes_file}'"
          MB.ui.say ex
          exit(1)
        end

        job = environment_manager.async_configure(environment, attributes: attributes, force: options[:force])

        CliClient.new(job).display
      end

      method_option :yes,
        type: :boolean,
        default: false,
        desc: "Don't confirm, just destroy the environment",
        aliases: '-y'
      desc "destroy ENVIRONMENT", "Destroy a provisioned environment"
      def destroy(environment)
        destroy_options = Hash.new.merge(options).deep_symbolize_keys

        dialog = "This will destroy the '#{environment}' environment.\nAre you sure? (yes|no): "
        really_destroy = options[:yes] || ui.yes?(dialog)

        if really_destroy
          job = provisioner.async_destroy(environment, destroy_options)
          CliClient.new(job).display
        else
          ui.say("Aborting destruction of '#{environment}'")
        end
      end

      desc "list", "List all environments"
      def list
        ui.say "\n"
        ui.say "** listing environments"
        ui.say "\n"

        environment_manager.list.each do |env|
          ui.say env.name
        end
      end

      desc "lock ENVIRONMENT", "Lock an environment"
      def lock(environment)
        job = lock_manager.lock(environment)

        CliClient.new(job).display
      end

      desc "unlock ENVIRONMENT", "Unlock an environment"
      def unlock(environment)
        job = lock_manager.unlock(environment)

        CliClient.new(job).display
      end
    end
  end

  class CliGateway
    register(Cli::EnvironmentCommand, :environment, "environment", "Environment level commands")
  end
end
