module MotherBrain
  module Cli
    module Shell
      # @author Jamie Winsor <reset@riotgames.com>
      module Ext
        class << self
          def included(base)
            base.send(:include, ClassMethods)
            base.extend(ClassMethods)
          end
        end

        module ClassMethods
          # Mute the output of this instance of UI until {#unmute!} is called
          def mute!
            @mute = true
          end

          # Unmute the output of this instance of UI until {#mute!} is called
          def unmute!
            @mute = false
          end

          def say(message = "", color = nil, force_new_line = nil)
            return if quiet?

            super(message, color)
          end
          alias_method :info, :say

          def warn(message)          
            say(message, :yellow)
          end

          def deprecated(message)
            warn("[DEPRECATION] #{message}")
          end

          def error(message = "")
            raise AbstractFunction
          end
          alias_method :fatal, :error
        end
      end
    end
  end
end
