module MotherBrain
  class CliClient
    attr_reader :jobs

    def initialize(*jobs)
      @jobs = jobs
    end

    def display
      until jobs.all?(&:completed?)
        jobs.each do |job|
          status job
        end
      end

      jobs.each do |job|
        final_status job
      end
    end

    def final_status(job)
      puts "\r  [#{job.type}] #{job.state.to_s.capitalize}"
    end

    def status(job)
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
  end
end
