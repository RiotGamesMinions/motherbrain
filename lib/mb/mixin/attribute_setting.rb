module MotherBrain
  module Mixin
    # @author Jamie Winsor <jamie@vialstudios.com>
    # @author Justin Campbell <justin@justincampbell.me>
    module AttributeSetting
      extend Forwardable
      include MB::Logging

      # Set the appropriate attributes at the environment level to the desired version
      # for each component given
      #
      # @param [String] :env_id
      #   the name identifier of the environment to modify
      # @param [MB::Plugin] plugin
      #   the plugin to use for finding the appropriate version attributes
      # @param [Hash] :component_versions
      #   Hash of components and the versions to set them to
      #
      # @example setting the versions of multiple components on an environment
      #
      #   set_component_versions("test-environment",
      #     "component_one" => "1.0.0",
      #     "component_two" => "2.3.0"
      #   )
      def set_component_versions(env_id, plugin, component_versions)
        log.info "Setting component versions #{component_versions}"

        override_attributes = Hash.new

        component_versions.each do |component_name, version|
          version_hash = Hash.from_dotted_path(version_attribute(plugin, component_name), version)
          override_attributes.deep_merge!(version_hash)
        end

        Application.ridley.sync do
          env = environment.find!(env_id)
          env.override_attributes.merge!(override_attributes)
          env.save
        end
      end

      # Lock the cookbook versions on the target environment from the given hash of
      # cookbooks and versions
      #
      # @param [String] :env_id
      #   the name identifier of the environment to modify
      # @param [Hash] :cookbook_versions
      #   Hash of cookbooks and the versions to set them to
      #
      # @example setting cookbook versions on an environment
      #
      #   set_cookbook_versions("test-environment",
      #     "league" => "1.74.2",
      #     "pvpnet" => "3.2.0"
      #   )
      def set_cookbook_versions(env_id, cookbook_versions)
        log.info "Setting cookbook versions #{cookbook_versions}"

        Application.ridley.sync do
          env = environment.find!(env_id)
          env.cookbook_versions.merge!(cookbook_versions)
          env.save
        end
      end

      # Set arbitrary attributes at the environment level
      #
      # @param [String] :env_id
      #   the name identifier of the environment to modify
      # @param [Hash] :environment_attributes
      #   Hash of attributes and values
      #
      # @example setting multiple attributes on an environment
      #
      #   set_environment_attributes("test-environment",
      #     "foo"      => "bar",
      #     "baz.quux" => 42
      #   )
      def set_environment_attributes(env_id, environment_attributes)
        log.info "Setting environment attributes #{environment_attributes}"

        override_attributes = Hash.new

        environment_attributes.each do |attribute, value|
          attribute_hash = Hash.from_dotted_path(attribute, value)
          override_attributes.deep_merge!(attribute_hash)
        end

        Application.ridley.sync do
          env = environment.find!(env_id)
          env.override_attributes.deep_merge!(override_attributes)
          env.save
        end
      end


      private

        # retrieve the version attribute of a given component and raise if the
        # component is not versioned
        #
        # @param [#to_s] component_name
        #
        # @raise [ComponentNotVersioned]
        #
        # @return [String]
        def version_attribute(plugin, component_name)
          result = plugin.component!(component_name).version_attribute

          unless result
            raise ComponentNotVersioned.new component_name
          end

          log.info "Component '#{component_name}' versioned with '#{result}'"

          result
        end
    end
  end
end
