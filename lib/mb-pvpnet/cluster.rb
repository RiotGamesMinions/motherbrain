module MotherBrain
  module Pvpnet
    class Cluster < Struct.new(:name, :connection)
      def start
        self.name
      end

      def stop
        self.name
      end

      def status
        connection.environment.all
      end

      def update(version)
        self.name + version
      end
    end
  end
end
