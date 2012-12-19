module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class JobRecord
    include MB::Job::States

    attr_reader :id
    attr_reader :result
    attr_reader :state
    attr_reader :status
    attr_reader :type

    # @param [Job] job
    def initialize(job)
      @id = job.id
      mass_assign(job)
    end

    # Update the instantiated JobRecord with the attributes of the given Job
    #
    # @param [Job] job
    #   the updated job to update the record with
    #
    # @return [self]
    def update(job)
      mass_assign(job)
      self
    end

    private

      def mass_assign(job)
        @result = job.result
        @state  = job.state
        @status = job.status
        @type   = job.type
      end
  end
end
