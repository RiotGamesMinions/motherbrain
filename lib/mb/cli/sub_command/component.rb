module MotherBrain
  module Cli
    module SubCommand
      # @author Jamie Winsor <reset@riotgames.com>
      class Component < SubCommand::Base
        class << self
          extend Forwardable

          def_delegator :component, :description

          # Return the component associated with this instance of the class
          #
          # @return [MB::Component]
          attr_reader :component

          # @param [MB::Component] component
          #
          # @return [SubCommand::Component]
          def fabricate(component)
            klass = Class.new(self) do
              set_component(component)
            end

            klass.component.commands.each do |command|
              klass.define_task(command)
            end

            klass.class_eval do
              desc("nodes ENVIRONMENT", "List all nodes grouped by Group")
              define_method(:nodes) do |environment|
                MB.ui.say "Listing nodes for '#{component.name}' in '#{environment}':"
                nodes = component.nodes(environment).each do |group, nodes|
                  nodes.collect! { |node| "#{node.public_hostname} (#{node.public_ipv4})" }
                end
                MB.ui.say nodes.to_yaml
              end
            end

            klass
          end

          # Set the component for this instance of the class and tailor the class for the
          # given component.
          #
          # @param [MB::Component] component
          def set_component(component)
            self.namespace(component.name)
            @component = component
          end
        end
      end
    end
  end
end
