module MotherBrain
  # @author Justin Campbell <justin@justincampbell.me>
  #
  # A class for encapsulating view behavior for a user of the CLI.
  #
  # @example
  #
  #   job = MotherBrain::Job.new
  #   CliClient.new(job).display
  #
  class CliClient
    attr_reader :jobs

    COLUMNS = `tput cols`.to_i
    SPACE = " "
    TICK = 0.1

    # @param [Array<MotherBrain::Job>] jobs
    def initialize(*jobs)
      @jobs = jobs
    end

    # Block and wait for all jobs to be completed, while displaying the status
    # of each job.
    def display
      wait and return if debugging?

      until jobs.all?(&:completed?)
        jobs.each do |job|
          status job
        end
      end

      jobs.each do |job|
        final_status job
      end
    end

    private

      def clear_line
        printf "\r#{SPACE * COLUMNS}"
      end

      # @return [Boolean]
      def debugging?
        MB.log.info?
      end

      # @param [MotherBrain::Job] job
      def final_status(job)
        clear_line

        puts "\r#{SPACE * spinner.next.length} [#{job.type}] #{job.state.to_s.capitalize}"
      end

      # @return [Enumerator]
      def spinner
        @spinner ||= Enumerator.new do |enumerator|
          characters = [
            %w[| / - \\],
            ["MB", "MB", "MB", "MB", "  "],
            ["MB", "  "],
            %w[` ' - . , . - ']
          # ].sample
          ].last

          loop do
            characters.each do |character|
              enumerator.yield character
            end
          end
        end
      end

      # @param [MotherBrain::Job] job
      def status(job)
        clear_line

        printf "\r%s [#{job.type}] #{job.status}", spinner.next

        sleep TICK
      end

      # @return [true]
      def wait
        sleep TICK until jobs.all?(&:completed?)

        true
      end
  end
end
