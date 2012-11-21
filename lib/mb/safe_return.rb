module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
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
      self[0] == :error
    end

    # @return [Boolean]
    def ok?
      self[0] == :ok
    end
  end
end
