module MotherBrain
  class CliClient
    attr_reader :job

    def initialize(job)
      @job = job
    end

    def display
      status job.status until job.completed?

      if job.state == :success
        MB.ui.say "Success"
      else
        MB.ui.say "Failed"
        exit 1
      end
    end

    def status(text)
      printf "\r%s #{text}", spinner.next

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
