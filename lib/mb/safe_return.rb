module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  #
  # A thin wrapper around an Array to provide a few helper functions for values
  # returned by {ActorUtil#safe_return}.
  #
  class SafeReturn < Array
    # @param [Symbol] status
    # @param [Object] body
    def initialize(status, body)
      super([status, body])
    end

    # @return [Symbol]
    def status
      self[0]
    end

    # @return [Object]
    def body
      self[1]
    end

    # @return [Boolean]
    def error?
      status == :error
    end

    # @return [Boolean]
    def ok?
      status == :ok
    end
  end
end
