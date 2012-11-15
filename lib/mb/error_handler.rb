module MotherBrain
  # @author Justin Campbell <justin@justincampbell.me>
  class ErrorHandler
    attr_reader :error_class

    OPTIONS = %w[caller_array method_name name path text version].map(&:to_sym)
    OPTIONS.each do |option|
      attr_reader option
    end

    def initialize(error_class, options = {})
      @error_class = error_class

      OPTIONS.each do |option|
        instance_variable_set "@#{option}", options[option]
      end
    end

    def message
      [
        name_and_version,
        path_and_line_number_and_method_name,
        text
      ].compact.join "\n"
    end

    def render
      raise error_class
    end

    def path_and_line_number_and_method_name
      buffer = []
      buffer << path if path
      buffer << "on line #{line_number}" if line_number
      buffer << "in '#{method_name}'" if method_name
      buffer.join ", "
    end

    def line_number
      if caller_array
        caller_array[0].split(":")[1].to_i
      end
    end

    def name_and_version
      if name and version
        "#{name} (#{version})"
      end
    end
  end
end
