require 'mb/mixin/attr_set'
require 'mb/plugin/components'

module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Plugin
    class << self
      # @param [String] content
      #
      # @raise [InvalidPlugin]
      def load(content)
        proxy = DSLProxy.new
        proxy.instance_eval(content)
        
        from_proxy(proxy)
      rescue ValidationFailed => e
        raise InvalidPlugin, e
      end

      private

        # @param [DSLProxy] proxy
        #
        # @return [Plugin]
        def from_proxy(proxy)
          obj = new(proxy.attributes)
          obj.components = proxy.components

          obj
        end
    end

    attr_reader :name
    attr_reader :version

    attr_accessor :description
    attr_accessor :author
    attr_accessor :email

    attr_writer :components

    # @param [Hash] attributes
    def initialize(attributes = {})
      @name = attributes.fetch(:name)
      @version = attributes.fetch(:version)

      @description = attributes.fetch(:description, "")
      @author = attributes.fetch(:author, "")
      @email = attributes.fetch(:email, "")
    end

    def components
      @components.values
    end

    def component(name)
      @components.fetch(name, nil)
    end

    # A proxy object to bind the values specified in a DSL to. The attributes of the
    # proxy object can later be given to the initializer of Plugin to create a new
    # instance of Plugin.
    #
    # @author Jamie Winsor <jamie@vialstudios.com>
    class DSLProxy
      include Mixin::AttrSet
      include Components

      # @param [String] value
      def name(value)
        set(:name, value, kind_of: String, required: true)
      end

      # @param [String] value
      def version(value)
        set(:version, value, kind_of: String, required: true)
      end

      # @param [String] value
      def description(value)
        set(:description, value, kind_of: String)
      end

      # @param [String, Array<String>] value
      def author(value)
        set(:author, value, kind_of: [String, Array])
      end

      # @param [String, Array<String>] value
      def email(value)
        set(:email, value, kind_of: [String, Array])
      end
    end
  end
end
