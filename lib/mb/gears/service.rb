module MotherBrain
  module Gear
    # @author Jamie Winsor <reset@riotgames.com>
    class Service < Gear::Base
      register_gear :service

      class << self
        # Finds a gear identified by name in the list of gears supplied.
        #
        # @param [Array<MB::Gear::Service>] gears
        #   the list of gears to search in
        # @param [#to_s] name
        #   the name of the gear to search for
        #
        # @return [MB::Gear::Service]
        def find(gears, name)
          gears.find { |obj| obj.name == name.to_s }
        end
      end

      # @return [String]
      attr_reader :name
      # @return [Set<Action>]
      attr_reader :actions
      # @return [MB::Component]
      attr_reader :component

      # @param [MB::Component] component
      # @param [#to_s] name
      def initialize(component, name, &block)
        @name      = name.to_s
        @component = component
        @actions   = Set.new

        if block_given?
          dsl_eval(&block)
        end
      end

      # Find and return the given action
      #
      # @param [String] name
      #
      # @raise [ActionNotFound] if there is no action of the given name defined
      #
      # @return [Gear::Action]
      def action(name)
        action = get_action(name)

        unless action
          raise ActionNotFound, "#{self.class.keyword} '#{_attributes_[:name]}' does not have the action '#{name}'"
        end

        action
      end

      # Add a new action to this Service
      #
      # @param [Service::Action] new_action
      #
      # @return [Set<Action>]
      def add_action(new_action)
        if get_action(new_action.name)
          raise DuplicateAction, "Action '#{new_action.name}' already defined on service '#{_attributes_[:name]}'"
        end

        actions << new_action
      end

      private

        def dsl_eval(&block)
          CleanRoom.new(self).instance_eval do
            instance_eval(&block)
          end
        end

        # @param [String] name
        def get_action(name)
          actions.find { |action| action.name == name }
        end

        # @author Jamie Winsor <reset@riotgames.com>
        # @api private
        class CleanRoom < CleanRoomBase
          # @param [String] name
          def action(name, &block)
            real_model.add_action Service::Action.new(name, real_model.component, &block)
          end

          private

            attr_reader :component
        end
    end

    require_relative 'service/action'
    require_relative 'service/action_runner'
  end
end
