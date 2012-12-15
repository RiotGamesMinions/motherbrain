module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class JobTicket
    extend Forwardable

    def_delegator :job, :id
    def_delegator :job, :status
    def_delegator :job, :result
    def_delegator :job, :completed?
    def_delegator :job, :finished?
    def_delegator :job, :failure?
    def_delegator :job, :pending?
    def_delegator :job, :running?
    def_delegator :job, :success?

    # @param [Integer] job_id
    def initialize(job_id)
      @job_id = job_id
    end

    private

      attr_reader :job_id

      # @return [Job]
      def job
        JobManager.instance.find(job_id)
      end
  end
end
