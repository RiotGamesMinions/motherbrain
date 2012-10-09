module MotherBrain
  module Gear
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Service
      include MB::Gear
      register_gear :service

      def run_action(name)
        runner = ActionRunner.new(self, action(name))
        self.context.runners ||= Array.new
        self.context.active_runner = runner
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
        self.context.active_runner.nodes.each do |l_node|
          puts "Setting attribute '#{key}' to '#{value}' on #{l_node[:name]}"

          self.context.chef_conn.sync do
            obj = node.find(l_node[:name])
            obj.set_override_attribute(key, value)
            obj.save
          end
        end
      end

      protected

        def action(name)
          self.actions.fetch(name) { 
            raise ActionNotFound, "#{self.class.keyword} '#{self.name}' does not have the action '#{name}'"
          }
        end
    end

    # @author Jamie Winsor <jamie@vialstudios.com>
    # @api private
    class ServiceProxy
      include ProxyObject

      def action(name, &block)
        if self.actions.has_key?(name)
          raise DuplicateAction, "Action '#{name}' already defined on service '#{self.attributes[:name]}'"
        end

        self.actions[name] = block
      end

      def attributes
        super.merge!(actions: self.actions)
      end

      protected

        def actions
          @actions ||= HashWithIndifferentAccess.new
        end
    end
  end
end
