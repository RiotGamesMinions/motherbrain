module MotherBrain
  class Job
    # @author Jamie Winsor <jamie@vialstudios.com>
    module Status
      PENDING = 'pending'.freeze
      RUNNING = 'running'.freeze
      SUCCESS = 'success'.freeze
      FAILURE = 'failure'.freeze
    end
  end
end
