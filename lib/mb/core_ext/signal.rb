module Signal
  class << self
    # Check if a given signal is supported on the current platform
    #
    # @param [#to_s] id
    #   the signal ID
    def supported?(id)
      list.has_key?(id.to_s)
    end
  end
end
