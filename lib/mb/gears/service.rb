module MotherBrain
  module Gear
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Service
      include MB::Gear
      register_gear :service

      attr_reader :actions

      def initialize(&block)
        @actions = Hash.new

        if block_given?
          dsl_eval(&block)
        end
      end

      def run_action(name)
        runner = ActionRunner.new(self, action(name))
        self.context.runners ||= Array.new
        self.context.runners << runner
        runner
      end

      def environment_attribute(key, value)
        puts "Setting attribute '#{key}' to '#{value}' on #{self.context.environment}"
        self.context.chef_conn.sync do
          obj = environment.find(self.context.environment)
          obj.set_override_attribute(key, value)
          obj.save
        end
      end

      def node_attribute(key, value)
        self.context.nodes.each do |l_node|
          puts "Setting attribute '#{key}' to '#{value}' on #{l_node[:name]}"

          self.context.chef_conn.sync do
            obj = node.find(l_node[:name])
            obj.set_override_attribute(key, value)
            obj.save
          end
        end
      end

      def action(name)
        self.actions.fetch(name) { 
          raise ActionNotFound, "#{self.class.keyword} '#{self.name}' does not have the action '#{name}'"
        }
      end

      def add_action(name, proc)
        if self.actions.has_key?(name)
          raise DuplicateAction, "Action '#{name}' already defined on service '#{self.attributes[:name]}'"
        end

      end

      private

        def dsl_eval(&block)
          self.attributes = CleanRoom.new(self, &block).attributes
          self
        end

      # @author Jamie Winsor <jamie@vialstudios.com>
      # @api private
      class CleanRoom
        include Mixin::SimpleAttributes

        def initialize(gear, &block)
          @gear = gear
          instance_eval(&block)
        end

        # @param [String] value
        def name(value)
          set(:name, value, kind_of: String, required: true)
        end

        def action(name, &block)
          gear.add_action(name, block)
        end

        private

          attr_reader :gear
      end
    end
  end
end
