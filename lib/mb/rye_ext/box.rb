module Rye
  class Box
    alias_method :original_create_channel, :create_channel

    def create_channel
      stdout_hook do |data|
        MB.log.info "NODE[#{host}] #{data}"
      end

      original_create_channel
    end
  end
end
