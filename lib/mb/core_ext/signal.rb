# @author Jamie Winsor <reset@riotgames.com>
module Signal
  class << self
    def supported?(id)
      list.has_key?(id)
    end
  end
end
