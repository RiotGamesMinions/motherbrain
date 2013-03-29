module MotherBrain
  # @author Jamie Winsor <reset@riotgames.com>
  #
  # The base module for defining new Gears for a plugin. Any class including this module
  # and registered with {MotherBrain} as a {Gear} will be available for use in the plugin DSL.
  #
  # Gears represent the proverbial knobs and levers that can be used to manipulate a
  # {Component}.
  #
  # @example Defining a new Gear
  #
  #   class Twitter < MotherBrain::AbstractGear
  #     register_gear :twitter
  #   end
  #
  # @example Plugin DSL usage
  #
  #   component "news_post" do
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
  end
end

Dir["#{File.dirname(__FILE__)}/gears/*.rb"].sort.each do |path|
  basename = File.basename(path, '.rb')

  begin
    require "mb/gears/#{basename}"
  rescue LoadError => error
    # puts "Error loading #{basename} gear: #{error.message}"
  end
end
