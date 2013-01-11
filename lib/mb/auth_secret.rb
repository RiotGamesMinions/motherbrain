require 'bcrypt'

module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class AuthSecret
    class << self
      # @return [AuthSecret]
      def generate
        BCrypt::Engine.generate_salt
      end

      # @param [String] data
      #
      # @return [AuthSecret]
      def from_string(data)
        new(data)
      end
    end

    # @return [String]
    attr_reader :key
    alias_method :key, :to_s

    # @param [#to_s] key
    def initialize(key = self.class.generate)
      @key = key.to_s
    end    
  end
end
