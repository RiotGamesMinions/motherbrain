module MotherBrain
  module Mixin
    # @author Jamie Winsor <reset@riotgames.com>
    # @author Justin Campbell <justin.campbell@riotgames.com>
    module AttributeSetting
      extend Forwardable
      include MB::Logging

      # Set the appropriate attributes at the environment level to the desired version
      # for each component given
      #
      # @param [String] env_id
      #   the name identifier of the environment to modify
      # @param [MB::Plugin] plugin
      #   the plugin to use for finding the appropriate version attributes
      # @param [Hash] component_versions
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
      # @param [String] env_id
      #   the name identifier of the environment to modify
      # @param [Hash] cookbook_versions
      #   Hash of cookbooks and the versions to set them to
      #
      # @example setting cookbook versions on an environment
      #
      #   set_cookbook_versions("test-environment",
      #     "league" => "1.74.2",
      #     "pvpnet" => "3.2.0"
      #   )
      #
      # @raise [ArgumentError] if given invalid version constraints
      def set_cookbook_versions(env_id, cookbook_versions)
        cookbook_versions = expand_constraints(expand_latest_versions(cookbook_versions))
        satisfies_constraints?(cookbook_versions)

        log.info "Setting cookbook versions #{cookbook_versions}"

        Application.ridley.sync do
          env = environment.find!(env_id)
          env.cookbook_versions.merge!(cookbook_versions)
          env.save
        end
      end

      # Set environment level attributes on an environment from a hash containing
      # keys identifying attributes using the dot notation syntax and values of those
      # attributes as values.
      #
      # @param [String] env_id
      #   the name identifier of the environment to modify
      # @param [Hash] new_attributes
      #   Hash of attributes and values
      #
      # @example setting multiple attributes on an environment
      #
      #   set_environment_attributes("test-environment",
      #     "foo"      => "bar",
      #     "baz.quux" => 42
      #   )
      def set_environment_attributes(env_id, new_attributes)
        override_attributes = Hash.new

        new_attributes.each do |attribute, value|
          attribute_hash = Hash.from_dotted_path(attribute.to_s, value.to_s)
          override_attributes.deep_merge!(attribute_hash)
        end

        set_environment_attributes_from_hash(env_id, override_attributes)
      end

      # Set arbitrary attributes at the environment level
      #
      # @param [String] env_id
      #   the name of the environment to modify
      # @param [Hash] new_attributes
      #   Hash of attributes to set on the environment
      #
      # @example setting multiple attributes on an environment
      #
      #   set_environment_attributes_from_hash("test-environment",
      #     "foo" => "bar",
      #     "baz  => {
      #       "quux" => 42
      #     }
      #   )
      def set_environment_attributes_from_hash(env_id, new_attributes)
        Application.ridley.sync do
          env = environment.find!(env_id)
          env.override_attributes.deep_merge!(new_attributes)
          env.save
        end
      end

      # Set environment level attributes on an environment from the contents of the file
      # at the given filepath
      #
      # @param [String] env_id
      #   the name of the environment to modify
      # @param [String] filepath
      #   path to the file to read attributes from
      # @param [Symbol] type
      #   the type of the contents found within the file
      #
      # @raise [InvalidAttributesFile]
      #   if the contents of the attributes file are missing or not well formed
      # @raise [ArgumentError]
      #   if an unknown value for the 'type' parameter is specified
      def set_environment_attributes_from_file(env_id, filepath, type = :json)
        contents = nil
        File.open(filepath) { |f| contents = f.read }

        case type
        when :json
          set_environment_attributes_from_json(env_id, contents)
        else
          raise ArgumentError, "cannot read attributes from files of type: #{type}"
        end
      rescue MultiJson::DecodeError => ex
        raise InvalidAttributesFile, "Invalid JSON in #{filepath}: #{ex}"
      end

      # Set environment level attributes on an environment from the given JSON string
      #
      # @param [String] env_id
      #   the name of the environment to modify
      # @param [String] json
      #   the json to use as attributes
      def set_environment_attributes_from_json(env_id, json)
        set_environment_attributes_from_hash(env_id, MultiJson.decode(json))
      end

      private

        # retrieve the version attribute of a given component and raise if the
        # component is not versioned
        #
        # @param [MB::Plugin] plugin
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

        # Expand the "latest" cookbook versions to the latest verison number 
        # for the cookbook
        #
        # @param [Hash] cookbook_versions
        #   Hash of cookbooks and the versions
        #
        # @example expanding versions when 3.1.0 is the latest pvpnet cookbook
        #
        #   expand_latest_versions(
        #     "league" => "1.74.2",
        #     "pvpnet" => "latest"
        #   )
        # 
        #   # => {"league" => "1.74.2", "pvpnet" => "3.1.0"}
        def expand_latest_versions(cookbook_versions)
          expanded_cookbook_versions = cookbook_versions.map do |name, version|
            if version.downcase == "latest"
              Application.ridley.sync do
                version = cookbook.latest_version(name)
              end
            end
            [name, version]
          end

          Hash[expanded_cookbook_versions]
        end

        # Expand constraints strings given to their fully qualified constraint operators
        #
        # @param [Hash] cookbook_versions
        #   Hash of cookbooks and the versions
        #
        # @raise [ArgumentError] if the array of constraints contains an entry which is not in the
        #   correct version constraint format
        #
        # @example
        #   expand_constraints(
        #     "league" => "1.74.2",
        #     "pvpnet" => ">= 1.2.3"
        #   )
        #   
        #   # => { "league" => "= 1.74.2", "pvpnet" => ">= 1.2.3" }
        #
        # @return [Hash]
        def expand_constraints(cookbook_versions)
          expanded = cookbook_versions.collect do |name, constraint|
            [name, Solve::Constraint.new(constraint).to_s]
          end

          Hash[expanded]
        rescue Solve::Errors::InvalidConstraintFormat => ex
          raise ArgumentError, ex
        end

        # Ensure the chef server can satisfy the desired cookbook version constraints
        #
        # @param [Hash] cookbook_versions
        #   Hash of cookbooks and the versions
        #
        # @raise [MB::CookbookConstraintNotSatisfied]
        #   if the constraints cannot be satisfied
        def satisfies_constraints?(cookbook_versions)
          failures = cookbook_versions.collect do |name, constraint|
            Celluloid::Future.new {
              if Application.ridley.cookbook.satisfy(name, constraint).nil?
                "#{name} (#{constraint})"
              end
            }
          end.map(&:value).compact

          unless failures.empty?
            raise MB::CookbookConstraintNotSatisfied,
              "couldn't satisfy constraints for cookbook version(s): #{failures.join(', ')}"
          end
        end
    end
  end
end
