module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class AuthManager
    class << self
      # @raise [Celluloid::DeadActorError] if rest gateway has not been started
      #
      # @return [Celluloid::Actor(AuthManager)]
      def instance
        MB::Application[:auth_manager] or raise Celluloid::DeadActorError, "Auth manager not running"
      end

      # Path to the authorization secret
      #
      # @return [Pathname]
      def secret_path
        FileSystem.root.join('authorization.secret')
      end
    end

    include Celluloid
    include MB::Logging

    def initialize
      unless secret
        record_secret(AuthSecret.generate)
      end
    end

    # Validate that the given key is authorized
    #
    # @param [#to_s] key
    #
    # @return [Symbol] a symbol representing the authentiation response
    #   * :authorized
    #   * :unauthorized
    #   * :rate_limited
    def authenticate(key)
      :authenicated
    end

    # Write an authorization secret to the secret path of this AuthManager
    #
    # @param [#to_s] key
    #   a string, probably an AuthSecret, used as the authorization secret for this instance
    #   of AuthManager 
    def record_secret(key)
      File.open(self.class.secret_path, 'w+') { |f| f.write(key.to_s) }
    end

    # The in-use authorization secret for this instance of AuthManager
    #
    # @return [String, nil]
    def secret
      AuthSecret.from_string File.read(self.class.secret_path).chomp
    rescue
      nil
    end
  end
end
