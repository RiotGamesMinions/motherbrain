module MotherBrain
  # @author Justin Campbell <justin.campbell@riotgames.com>
  #
  # A class for encapsulating view behavior for a user of the CLI.
  #
  # @example
  #
  #   job = MotherBrain::Job.new
  #   CliClient.new(job).display
  #
  class CliClient
    COLUMNS = `tput cols`.to_i
    SPACE = " "
    TICK = 0.1

    attr_accessor :current_status
    attr_reader :job

    # @param [Array<MotherBrain::Job>] jobs
    def initialize(job)
      @job = job
    end

    # Block and wait for all jobs to be completed, while displaying the status
    # of each job.
    def display
      if debugging?
        wait_for_jobs
      else
        display_jobs
      end

      if job_failed?
        display_log_location if log_location
        abort
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

      def display_log_location
        puts "#{left_space} [motherbrain] Log written to #{log_location}"
      end

      def display_jobs
        until job_completed? || application_terminated?
          print_statuses
          sleep TICK
        end

        if application_terminated?
          print_final_terminated_status
        else
          print_final_status
        end
      end

      def job_completed?
        job.completed?
      end

      def job_failed?
        job.failed?
      end

      def job_type
        @job_type || job.type
      end

      def log_location
        MB::Logging.filename
      end

      def print_final_status
        print_with_new_line current_status

        msg = "#{left_space} [#{job_type}] #{job.state.to_s.capitalize}"
        msg << ": #{job.result}" if job.result

        puts msg
      end

      def print_final_terminated_status
        puts "\nMotherBrain terminated"
      end

      def left_space
        SPACE * spinner.peek.length
      end

      def print_statuses
        last_status = status_buffer.pop

        if last_status
          print_with_new_line current_status if current_status
          self.current_status = last_status
        end

        while status = status_buffer.shift
          print_with_new_line status
        end

        print_with_spinner current_status
      end

      def print_with_spinner(text)
        return unless text

        clear_line

        printf "\r%s [#{job_type}] #{text}", spinner.next
      end

      def print_with_new_line(text)
        return unless text

        clear_line

        printf "\r#{left_space} [#{job_type}] #{text}\n"
      end

      # @return [Enumerator]
      def spinner
        @spinner ||= Enumerator.new { |enumerator|
          characters = %w[` ' - . , . - ']

          loop {
            characters.each do |character|
              enumerator.yield character
            end
          }
        }
      end

      def status_buffer
        job.status_buffer
      end

      def wait_for_jobs
        sleep TICK until job.completed? || application_terminated?
      end
  end
end
