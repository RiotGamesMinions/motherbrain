# Code from https://github.com/wycats/thor/pull/317

class Thor
  module Shell
    class Basic
      def ask(statement, *args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        color = args.first

        if options[:limited_to]
          ask_filtered(statement, color, options)
        else
          ask_simply(statement, color, options)
        end
      end

      protected

      def ask_simply(statement, color, options)
        default = options[:default]
        message = [statement, ("(#{default.inspect})" if default), nil].uniq.join(" ")
        say(message, color)
        result = stdin.gets

        return unless result

        result.strip!

        if default && result == ""
          default
        else
          result
        end
      end

      def ask_filtered(statement, color, options)
        answer_set = options[:limited_to]
        correct_answer = nil
        until correct_answer
          answer = ask_simply("#{statement} #{answer_set.inspect}", color, options)
          correct_answer = answer_set.include?(answer) ? answer : nil
          answers = answer_set.map(&:inspect).join(", ")
          say("Your response must be one of: [#{answers}]. Please try again.") unless correct_answer
        end
        correct_answer
      end
    end
  end
end
