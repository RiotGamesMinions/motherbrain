module MotherBrain
  module PluginDSL
    # @author Jamie Winsor <jamie@vialstudios.com>
    module Dependencies
      # @return [HashWithIndifferentAccess]
      def dependencies
        @dependencies ||= HashWithIndifferentAccess.new
      end

      def depends(name, constraint)
        constraint = Solve::Constraint.new(constraint)

        add_dependency(name, constraint)
      end

      private

        # @param [#to_s] name
        # @param [Solve::Constraint] constraint
        def add_dependency(name, constraint)
          self.dependencies[name.to_s] = constraint
        end
    end
  end
end
