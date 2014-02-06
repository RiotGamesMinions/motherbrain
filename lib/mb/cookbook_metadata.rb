module MotherBrain
  class CookbookMetadata < ::Ridley::Chef::Cookbook::Metadata

    RUBY_FILENAME = 'metadata.rb'.freeze
    JSON_FILENAME = 'metadata.json'.freeze

    class << self
      # @return [Cookbook::Metadata]
      def load(&block)
        klass = new()
        klass.instance_eval(&block) if block_given?
        klass
      end

      # @param [#to_s] filepath
      #
      # @return [Cookbook::Metadata]
      def from_file(filepath)
        filepath = filepath.to_s

        if File.extname(filepath) =~ /\.json/
          from_json_file(filepath)
        else
          from_ruby_file(filepath)
        end
      end

      # @param [#to_s] path
      #
      # @return [Cookbook::Metadata]
      def from_path(path)
        ruby_file     = File.join(path, RUBY_FILENAME)
        json_file     = File.join(path, JSON_FILENAME)
        metadata_file = File.exists?(json_file) ? json_file : ruby_file

        from_file(metadata_file)
      end

      private

        def from_ruby_file(filepath)
          load { eval(File.read(filepath), binding, filepath, 1) }
        end

        def from_json_file(filepath)
          load { from_json(File.read(filepath)) }
        end
    end

    def initialize(&block)
      super
      self.instance_eval(&block) if block_given?
    end

    def version(data = nil)
      @version = data.nil? ? @version : Solve::Version.new(data)
    end

    # TODO
    def valid?
      true
    end

    private

      def method_missing(*args); nil end

  end
end
