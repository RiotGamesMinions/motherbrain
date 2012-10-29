module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  #
  # The base module for defining new Gears for a plugin. Any class including this module
  # and registered with {MotherBrain} as a {Gear} will be available for use in the plugin DSL.
  #
  # Gears represent the proverbial knobs and levers that can be used to manipulate a
  # {Component}.
  #
  # @example Defining a new Gear
  #
  #   class Twitter
  #     include MotherBrain::Gear
  #     register_gear :twitter
  #   end
  #
  # @example Plugin DSL usage
  #
  #   component do
  #     name "news_post"
  #
  #     twitter do
  #     ...
  #     end
  #   end
  #
  module Gear    
    RESERVED_KEYWORDS = [
      :name,
      :version,
      :description,
      :author,
      :email,
      :depends,
      :command,
      :component,
      :group,
      :execute
    ]

    class << self
      # Registers a given Class as a Gear to be used within MotherBrain plugins. This
      # function is automatically called when {MotherBrain::Gear} is included into
      # a Class. You probably don't want to call this function directly.
      #
      # @api private
      #
      # @param [~MotherBrain::Gear] klass
      def register(klass)
        validate_keyword(klass.keyword)

        all.add(klass)
      end

      # Return a Set containing all of the registered Gears that can be used within
      # a MotherBrain plugin.
      #
      # @return [Set<MotherBrain::Gear>]
      def all
        @all ||= Set.new
      end

      # Clears all of the registered Gears and then traverses the ObjectSpace to find
      # all classes which include {MotherBrain::Gear} and calls {::register} with each.
      #
      # @return [Set<MotherBrain::Gear>]
      #   the Set of registered Gears
      def reload!
        clear!
        ObjectSpace.each_object(::Module).each do |mod|
          if mod < MB::Gear
            register(mod)
          end
        end

        all
      end

      # Clears all of the registered Gears.
      #
      # @return [Set]
      #   an empty Set
      def clear!
        @all = Set.new
      end

      # @param [Symbol] keyword
      #
      # @return [MotherBrain::Gear, nil]
      def find_by_keyword(keyword)
        all.find { |klass| klass.keyword == keyword }
      end

      def element_name(klass)
        klass.keyword
      end

      def get_fun(klass)
        element_name(klass)
      end

      private

        # Determine if the given keyword is valid
        #
        # @param [Symbol] keyword
        #
        # @raise [ReservedGearKeyword] if the given keyword is reserved
        # @raise [DuplicateGearKeyword] if the given keyword has already been registered
        #
        # @return [Boolean]
        def validate_keyword(keyword)
          if RESERVED_KEYWORDS.include?(keyword)
            reserved = RESERVED_KEYWORDS.collect { |key| "'#{key}'" }
            raise ReservedGearKeyword, "'#{keyword}' is a reserved keyword. Reserved Keywords: #{reserved.join(', ')}."
          end

          culprit = find_by_keyword(keyword)

          unless culprit.nil?
            raise DuplicateGearKeyword, "Keyword '#{keyword}' already used by #{culprit}"
          end

          true
        end
    end

    extend ActiveSupport::Concern

    included do
      class_eval do
        include Mixin::SimpleAttributes
      end
    end

    module ClassMethods
      # The identifier for the Gear. The keyword is automatically populated based on the name
      # of the Class including {MotherBrain::Gear}. The keyword must be unique among the other
      # registered Gears. Also used to define a Gear in the plugin DSL.
      #
      # @return [Symbol]
      attr_reader :keyword

      # Register the gear with {MotherBrain::Gear} with the given keyword. This is how a gear is
      # identified within a plugin.
      # 
      # @param [#to_sym] keyword
      def register_gear(keyword)
        @keyword = keyword.to_sym
        Gear.register(self)
      end
    end
  end
end

Dir["#{File.dirname(__FILE__)}/gears/*.rb"].sort.each do |path|
  require "mb/gears/#{File.basename(path, '.rb')}"
end
