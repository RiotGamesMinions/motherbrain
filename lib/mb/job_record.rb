module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class JobRecord
    include MB::Job::States

    attr_reader :id
    attr_reader :type
    attr_reader :state
    attr_reader :result

    # @param [Job] job
    def initialize(job)
      mass_assign(job)
    end

    # @param [Job] job
    #
    # @return [self]
    def update(job)
      mass_assign(job)
      self
    end

    private

      def mass_assign(job)
        @id     = job.id
        @type   = job.type
        @state  = job.state
        @result = job.result
      end
  end
end
