module MotherBrain
  module Cli
    # @author Jamie Winsor <reset@riotgames.com>
    module Shell
      autoload :Basic, 'mb/cli/shell/basic'
      autoload :Color, 'mb/cli/shell/color'
      autoload :Ext, 'mb/cli/shell/ext'

      class << self
        attr_writer :shell

        # Returns the shell used in the motherbrain CLI. If you are in a Unix platform
        # it will use a colored shell, otherwise it will use a color-less one.
        #
        # @return [Shell::Basic, Shell::Color]
        def shell
          @shell ||= if ENV['MB_SHELL'] && ENV['MB_SHELL'].size > 0
            Shell.const_get(ENV['MB_SHELL'].capitalize)
          elsif Chozo::Platform.windows? && !ENV['ANSICON']
            Shell::Basic
          else
            Shell::Color
          end
        end
      end

      ::Thor::Base.shell = shell
    end
  end
end
