module MotherBrain
  class CliClient
    attr_reader :jobs

    COLUMNS = `tput cols`.to_i

    def initialize(*jobs)
      @jobs = jobs
    end

    def debugging?
      MB.log.info?
    end

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

    def clear_line
      printf "\r#{' ' * COLUMNS}"
    end

    def final_status(job)
      clear_line

      puts "\r  [#{job.type}] #{job.state.to_s.capitalize}"
    end

    def status(job)
      clear_line

      printf "\r%s [#{job.type}] #{job.status}", spinner.next

      sleep 0.1
    end

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

    def wait
      sleep 0.1 until jobs.all?(&:completed?)

      true
    end
  end
end
