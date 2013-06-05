module MotherBrain
  module Cli
    module Shell
      class Basic < Thor::Shell::Basic
        include MB::Cli::Shell::Ext

        alias_method :fatal, :error
      end
    end
  end
end
