module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Plugin
    class << self
      # @param [MotherBrain::Context] context
      # @param [String] content
      #
      # @raise [InvalidPlugin]
      #
      # @return [MotherBrain::Plugin]
      def load(context, content)
        plugin = new(context)
        proxy = PluginProxy.new(plugin.context)
        proxy.instance_eval(content)
        plugin.attributes = proxy.attributes

        plugin
      rescue ValidationFailed => e
        raise InvalidPlugin, e
      end

      # @param [MotherBrain::Context] context
      # @param [String] path
      #
      # @return [MotherBrain::Plugin]
      def from_file(context, path)
        load(context, File.read(path))
      end

      def key_for(name, version)
        "#{name}-#{version}".to_sym
      end
    end

    include RealObject

    attr_accessor :attributes

    # @param [MotherBrain::Context] context
    # @param [Hash] attributes
    def initialize(context, attributes = {})
      @context = context.dup
      @attributes = attributes
      @context.plugin = self
    end

    # @return [Symbol]
    def id
      self.class.key_for(self.name, self.version)
    end

    def components
      self.attributes[:components].values
    end

    def component(name)
      self.attributes[:components].fetch(name, nil)
    end

    def commands
      self.attributes[:commands].values
    end

    def command(name)
      self.attributes[:commands].fetch(name, nil)
    end
  end

  # A proxy object to bind the values specified in a DSL to. The attributes of the
  # proxy object can later be given to the initializer of Plugin to create a new
  # instance of Plugin.
  #
  # @author Jamie Winsor <jamie@vialstudios.com>
  # @api private
  class PluginProxy
    include Mixin::SimpleAttributes
    include PluginDSL::Components
    include PluginDSL::Commands
    include PluginDSL::Dependencies

    # @return [MotherBrain::Context]
    attr_reader :context

    # @param [MotherBrain::Context] context
    def initialize(context)
      @context = context
    end

    # @param [String] value
    def name(value)
      set(:name, value, kind_of: String, required: true)
    end

    # @param [String] value
    def version(value)
      begin
        value = Solve::Version.new(value)
      rescue Solve::Errors::SolveError => e
        raise ValidationFailed, e.message
      end
      set(:version, value, kind_of: Solve::Version, required: true)
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

    def attributes
      super.merge!(commands: self.commands, components: self.components, dependencies: self.dependencies)
    end
  end
end
