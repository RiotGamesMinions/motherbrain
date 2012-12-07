require 'tempfile'

module MotherBrain
  module FileSystem
    class Tempfile < ::Tempfile
      BASENAME = 'mb_'.freeze

      class << self
        def open(options = {})
          super(options)
        end
      end

      def initialize(options = {})
        super(BASENAME, FileSystem.tmpdir, options)
      end
    end
  end
end
