module MotherBrain
  module RSpec
    # @author Jamie Winsor <reset@riotgames.com>
    #
    # Pre-defined commonly used doubles for testing motherbrain
    module Doubles
      def job_double(name = "job")
        double(name, alive?: true, terminate: nil, set_status: nil, report_running: nil,
          report_failure: nil, report_pending: nil, report_success: nil, report_boolean: nil)
      end
    end
  end
end
