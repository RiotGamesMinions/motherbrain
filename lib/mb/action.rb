module MotherBrain
  module Action
    class Action
      def run(nodes)
        raise NotImplementedError
      end
    end
  end
end

Dir["#{File.dirname(__FILE__)}/actions/*.rb"].sort.each do |path|
  require "mb/actions/#{File.basename(path, '.rb')}"
end
