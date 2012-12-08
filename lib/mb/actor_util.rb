module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  #
  # Helper functions for Celluloid Actors
  #
  module ActorUtil
    # Run the given block and return an array of two elements based on the evaluated results. This
    # response array will contain a status code at index 0 and the yield of the block at index 1.
    #
    # If the given block evaluates without exception the response array will contain the ':ok' status.
    #
    # If the given block raises an exception the response array will contain the ':error' status and
    # the body of the response array will contain the exception.
    #
    # @param [Array] exceptions
    #
    # @raise [LocalJumpError] if no block is given
    #
    # @return [SafeReturn]
    #   Return a response array containing a status at index 0 and body at index 1
    def safe_return(*exceptions)
      unless block_given?
        raise ::LocalJumpError, "no block given (yield)"
      end

      if exceptions.nil? || exceptions.empty?
        exceptions = ::Exception
      end

      SafeReturn.new(:ok, yield)
    rescue *exceptions => e
      SafeReturn.new(:error, e)
    end
  end
end
