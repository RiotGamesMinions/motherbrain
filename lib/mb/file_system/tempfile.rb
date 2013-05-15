require 'tempfile'

module MotherBrain
  module FileSystem
    # @author Jamie Winsor <reset@riotgames.com>
    #
    # Thin wrapper around ::Tempfile to ensure we always write temporary files
    # into motherbrain's configured temporary directory
    class Tempfile < ::Tempfile
      BASENAME = 'mb_'.freeze

      class << self
        # @param [Hash] options
        #   options to pass to ::Tempfile.open
        def open(options = {})
          super(options)
        end
      end

      # @param [Hash] options
      #   options to pass to ::Tempfile.new
      def initialize(options = {})
        super(BASENAME, FileSystem.tmpdir, options)
      end
    end
  end
end
