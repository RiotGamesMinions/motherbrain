module MotherBrain
  # @author Justin Campbell <justin@justincampbell.me>
  class ErrorHandler
    def self.wrap(error, options = {})
      error_handler = new error, options

      raise error_handler.error, error_handler.message
    end

    attr_reader :error

    OPTIONS = %w[
      caller_array
      file_path
      method_name
      plugin_name
      plugin_version
      text
    ].map(&:to_sym)

    OPTIONS.each do |option|
      attr_reader option
    end

    def initialize(error, options = {})
      @error = error

      extract_data_from_options options
      extract_data_from_error

      embed_data_in_error
    end

    def extract_data_from_options(options)
      OPTIONS.each do |option|
        data = options[option]

        instance_variable_set "@#{option}", data
      end
    end

    def extract_data_from_error
      OPTIONS.each do |option|
        data = error.send option if error.respond_to? option

        unless instance_variable_get "@#{option}"
          instance_variable_set "@#{option}", data
        end
      end

      @caller_array ||= error.backtrace
      @method_name || error.name if error.respond_to? :name
      @text ||= error.message
    end

    def message
      [
        plugin_name_and_plugin_version,
        file_path_and_line_number_and_method_name,
        text
      ].compact.join "\n"
    end

    def embed_data_in_error
      OPTIONS.each do |option|
        data = instance_variable_get "@#{option}"

        if data
          error.instance_eval "def #{option}; @_error_handler_#{option}; end"
          error.instance_variable_set "@_error_handler_#{option}", data
        end
      end
    end

    def file_path_and_line_number_and_method_name
      buffer = []
      buffer << file_path if file_path
      buffer << "on line #{line_number}" if line_number
      buffer << "in '#{method_name}'" if method_name
      buffer.join ", "
    end

    def line_number
      if caller_array
        caller_array[0].split(":")[1].to_i
      end
    end

    def plugin_name_and_plugin_version
      if plugin_name and plugin_version
        "#{plugin_name} (#{plugin_version})"
      end
    end
  end
end
