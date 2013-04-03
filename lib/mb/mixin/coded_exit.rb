module MotherBrain
  module Mixin
    # @author Jamie Winsor <reset@riotgames.com>
    #
    # Include a collection of helper functions for exiting with exit statuses from error constants
    # and determining exit statuses for string representations of motherbrain exceptions.
    module CodedExit
      class << self
        def included(base)
          base.extend(ClassMethods)
          base.include(ClassMethods)
        end
      end

      module ClassMethods
        # Exit the application with the exit status associated with the given motherbrain error
        #
        # @param [String, #exit_code] obj
        #
        # @example exit the application with an exit status for InvalidConfig (14)
        #   exit_with(MB::InvalidConfig)
        #
        # @raise [SystemExit]
        def exit_with(obj)
          err_const = obj.is_a?(String) ? constant_for(obj) : obj
          exit_code = err_const.try(:exit_code) || MBError::DEFAULT_EXIT_CODE

          Kernel.exit(exit_code)
        end

        # Look up the exit status for motherbrain error matching the given name
        #
        # @param [String] const_name
        #   name of the error constant to lookup
        #
        # @example retrieving the exit status for MB::InvalidConfig
        #   exit_code_for("InvalidConfig") #=> 14
        #
        # @return [Integer]
        def exit_code_for(const_name)
          MB.const_get(const_name).exit_code
        end
        alias_method :exit_status_for, :exit_code_for
      end
    end
  end
end
