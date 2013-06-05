module MotherBrain
  # An object to help with the display of errors in a more user-friendly format.
  # An ErrorHandler is created with an error and a set of options to control the
  # display of the error. Some options can be inferred from the error itself.
  # A typical use case would be to wrap an error generated deep in a call stack,
  # and then add data to the error as it bubbles up.
  #
  # @example Wrapping and raising an error with more data
  #
  #   ErrorHandler.wrap StandardError.new,
  #     file_path: "/a/b/c.rb",
  #     method_name: :wat,
  #     plugin_name: "hi",
  #     plugin_version: "1.2.3",
  #     text: "Invalid thing"
  #
  #   # Would raise an error with a message of:
  #
  #   hi (1.2.3)
  #   /a/b/c.rb, on line 1, in 'wat'
  #   Invalid thing
  #
  # @example Wrapping an error at multiple points in the call chain
  #
  #   def load_file(path)
  #     load File.read(path)
  #   rescue => error
  #     ErrorHandler.wrap error, file_path: path
  #   end
  #
  #   def load(code)
  #     eval code
  #   rescue => error
  #     ErrorHandler.wrap error, plugin_name: code.lines.to_a.first
  #   end
  #
  #   def method_missing(method_name, *args, &block)
  #     ErrorHandler.wrap CodeError.new, method_name: method_name
  #   end
  #
  #
  class ErrorHandler
    NEWLINE = "\n"
    SOURCE_RANGE = 5

    class << self
      # Wraps an error with additional data and raises it.
      #
      # @raise [StandardError]
      # @see #initialize
      def wrap(error, options = {})
        error_handler = new(error, options)

        raise error_handler.error, error_handler.message
      end
    end

    attr_reader :error

    OPTIONS = %w[
      backtrace
      file_path
      method_name
      plugin_name
      plugin_version
      text
    ].map(&:to_sym)

    OPTIONS.each do |option|
      attr_reader option
    end

    # @param [StandardError] error
    #
    # @option options [Array] backtrace
    #   An array of strings containing filenames, line numbers, and method
    #   names. Typically comes from `caller`.
    #
    # @option options [String] file_path
    #   The location of a file on disk to display to the user.
    #
    # @option options [Symbol] method_name
    #   The name of the method or keyword which generated the error.
    #
    # @option options [String] plugin_name
    #   The name of the plugin the error relates to.
    #
    # @option options [String] plugin_version
    #   The version of the plugin the error relates to.
    #
    # @option options [String] text
    #   A custom error message to display to the user.
    #
    def initialize(error, options = {})
      error = error.new if error.is_a? Class

      @error = error

      extract_data_from_options options
      extract_data_from_error

      embed_data_in_error
    end

    # Extracts data from an options hash and stores it in instance variables.
    #
    # @param [Hash] options
    #
    # @see #initialize
    def extract_data_from_options(options)
      OPTIONS.each do |option|
        instance_variable_set "@#{option}", options[option]
      end
    end

    # Extracts data from the error and stores it in instance variables. Does not
    # overwrite existing instance variables.
    def extract_data_from_error
      OPTIONS.each do |option|
        data = error.instance_variable_get "@_error_handler_#{option}"

        unless instance_variable_get "@#{option}"
          instance_variable_set "@#{option}", data
        end
      end

      @backtrace ||= error.backtrace
      @method_name ||= error.name if error.respond_to? :name
      @text ||= error.message
    end

    # Stores the data in the error and defines getters.
    def embed_data_in_error
      OPTIONS.each do |option|
        data = instance_variable_get "@#{option}"

        if data
          error.instance_variable_set "@_error_handler_#{option}", data
        end
      end
    end

    # @return [String]
    def message
      result = [
        plugin_name_and_plugin_version,
        file_path_and_line_number_and_method_name,
        text,
        relevant_source_lines
      ].compact.join NEWLINE

      result << NEWLINE unless result.end_with? NEWLINE

      result
    end

    # @return [String]
    def file_contents
      return unless file_path and File.exist? file_path

      File.read file_path
    end

    # @return [String]
    def relevant_source_lines
      return unless file_contents and line_number

      beginning = line_number - (SOURCE_RANGE / 2) - 1
      beginning = [beginning, 0].max
      numbered_source_lines[beginning, SOURCE_RANGE].join NEWLINE
    end

    # @return [Array]
    def numbered_source_lines
      lines = file_contents.lines.to_a.map(&:rstrip)
      rjust_size = lines.count.to_s.length

      result = []

      lines.each_with_index do |line, index|
        current_line_number = index + 1

        result << "#{current_line_number.to_s.rjust rjust_size}#{line_number == current_line_number ? '>>' : ': '}#{line}"
      end

      result
    end

    # @return [String]
    def file_path_and_line_number_and_method_name
      buffer = []
      buffer << file_path if file_path
      buffer << "on line #{line_number}" if line_number
      buffer << "in '#{method_name}'" if method_name
      buffer.join ", "
    end

    # @return [String]
    def plugin_name_and_plugin_version
      "#{plugin_name} (#{plugin_version})" if plugin_name and plugin_version
    end

    # Extracts the first line number from the backtrace.
    #
    # @return [Fixnum]
    def line_number
      return unless backtrace and backtrace[0]

      backtrace[0].split(":")[1].to_i
    end
  end
end
