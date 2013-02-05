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
      if debugging?
        wait_for_jobs
      else
        display_jobs
      end
    end

    private

      def application_terminated?
        JobManager.stopped?
      end

      def clear_line
        printf "\r#{SPACE * COLUMNS}"
      end

      # @return [Boolean]
      def debugging?
        MB.log.info?
      end

      def display_jobs
        until jobs.all?(&:completed?) || application_terminated?
          jobs.each do |job|
            print_status job
          end
        end

        if application_terminated?
          print_final_terminated_status
        else
          jobs.each do |job|
            print_final_status job
          end
        end
      end

      # @param [MotherBrain::Job] job
      def print_final_status(job)
        print_last_status(job)

        msg = "#{SPACE * spinner.next.length} [#{job.type}] #{job.state.to_s.capitalize}"
        msg << ": #{job.result}" if job.result

        puts msg
      end

      def print_final_terminated_status
        puts "\nMotherBrain terminated"
      end

      def last_statuses
        @last_statuses ||= Hash.new
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
      def print_status(job)
        if last_statuses[job] && job.status != last_statuses[job]
          print_last_status(job)
        end

        clear_line

        printf "\r%s [#{job.type}] #{job.status}", spinner.next

        last_statuses[job] = job.status

        sleep TICK
      end

      def print_last_status(job)
        clear_line

        printf "\r#{SPACE * spinner.next.length} [#{job.type}] #{last_statuses[job]}\n"
      end

      def wait_for_jobs
        sleep TICK until jobs.all?(&:completed?) || application_terminated?
      end
  end
end
