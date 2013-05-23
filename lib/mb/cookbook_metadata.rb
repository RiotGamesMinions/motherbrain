module MotherBrain
  # @author Jamie Winsor <reset@riotgames.com>
  class CookbookMetadata
    class << self
      # @return [Cookbook::Metadata]
      def load(&block)
        new(&block)
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
          load {
            json_metadata = JSON.parse(File.read(filepath))
            json_metadata.each { |key, val| send(key.to_sym, val) }
          }
        end
    end

    RUBY_FILENAME = 'metadata.rb'.freeze
    JSON_FILENAME = 'metadata.json'.freeze

    include Chozo::VariaModel

    attribute :name,
      type: String

    attribute :maintainer,
      type: String

    attribute :maintainer_email,
      type: String

    attribute :license,
      type: String

    attribute :description,
      type: String

    attribute :long_description,
      type: String

    attribute :version,
      type: Solve::Version,
      required: true,
      coerce: lambda { |m|
        Solve::Version.new(m)
      }

    def initialize(&block)
      dsl_eval(&block) if block_given?
    end

    private

      def dsl_eval(&block)
        CleanRoom.new(self).instance_eval(&block)
      end

    # @author Jamie Winsor <reset@riotgames.com>
    # @api private
    class CleanRoom < CleanRoomBase
      dsl_attr_writer :name
      dsl_attr_writer :maintainer
      dsl_attr_writer :maintainer_email
      dsl_attr_writer :license
      dsl_attr_writer :description
      dsl_attr_writer :long_description
      dsl_attr_writer :version

      private

        def method_missing(*args); nil end
    end
  end
end
