RSpec::Matchers.define :be_error_code do |error_constant|
  match do |actual|
    error_constant.error_code == actual
  end
end

module MotherBrain
  module Matchers
    class ExitCodes
      include MB::Mixin::CodedExit

      def initialize(target_err)
        @target_err = target_err
        @actual_err = nil
      end

      def matches?(given_proc)
        given_proc.call
      rescue SystemExit => @actual_err
        return false unless target_has_exit_code?

        @actual_status = @actual_err.status
        @target_status = @target_err.exit_code

        if @actual_status.nil? || @target_status.nil?
          return false
        end

        return @actual_status == @target_status
      end

      def failure_message_for_should
        unless target_has_exit_code?
          msg = "the program exited but the exception the exception you you gave does not respond to" +
            " #exit_code. Is it an MB::MBError?"
          return msg
        end

        "the program exited with an exit status of #{@actual_status} but you expected it to be #{@target_status}."
      end

      def failure_message_for_should_not
        unless target_has_exit_code?
          msg = "the program exited but the exception the exception you you gave does not respond to" +
            " #exit_code. Is it an MB::MBError?"
          return msg
        end

        "the program exited with an exit status of #{@actual_status} but you expected it not to."
      end

      private

        def target_has_exit_code?
          @target_err.respond_to?(:exit_code)
        end
    end

    def exit_with(err_const)
      Matchers::ExitCodes.new(err_const)
    end
  end
end
