module MotherBrain
  module Cli
    module Shell
      class Color < Thor::Shell::Color
        include MB::Cli::Shell::Ext

        alias_method :fatal, :error
      end
    end
  end
end
