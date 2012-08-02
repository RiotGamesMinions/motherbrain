require 'set'
require 'active_model'
require 'active_support/all'

module Mixed
  class MixedError < StandardError; end
  class ConfigNotFound < MixedError; end
  class InvalidConfig < MixedError; end

  module JSONConfig
    extend ActiveSupport::Concern
    include ActiveModel::AttributeMethods
    include ActiveModel::Validations
    include ActiveModel::Serializers::JSON

    included do
      attribute_method_suffix('=')
    end

    module ClassMethods
      def attributes
        @attributes ||= Set.new
      end

      def defaults
        @defaults ||= Hash.new
      end

      def attribute(name, options = {})
        if options[:default]
          default_for_attribute(name, options[:default])
        end
        define_attribute_method(name)
        attributes << name.to_sym
      end

      def from_json(data)
        new.from_json(data)
      end

      def from_file(path)
        data = File.read(path)
        new(path).from_json(data)
      rescue Errno::ENOENT, Errno::EISDIR
        raise ConfigNotFound, "No configuration found at: '#{path}'"
      end

      private

        def default_for_attribute(name, value)
          defaults[name.to_sym] = value
        end
    end

    def attribute(key)
      instance_variable_get("@#{key}") || self.class.defaults[key]
    end
    alias_method :[], :attribute

    def attribute=(key, value)
      instance_variable_set("@#{key}", value)
    end
    alias_method :[]=, :attribute=

    def attributes=(new_attributes)
      new_attributes.symbolize_keys!

      self.class.attributes.each do |attr_name|
        send(:attribute=, attr_name, new_attributes[attr_name.to_sym])
      end
    end

    def attribute?(key)
      instance_variable_get("@#{key}").present?
    end

    def attributes
      {}.tap do |attrs|
        self.class.attributes.each do |attr|
          attrs[attr] = attribute(attr)
        end
      end
    end

    def as_json(options = {})
      options.merge!(root: false)
      super(options)
    end

    def from_json(json, include_root = false)
      super(json, include_root)
    rescue MultiJson::DecodeError => e
      raise Mixed::InvalidConfig, e
    end

    def to_s
      self.attributes
    end
  end
end
