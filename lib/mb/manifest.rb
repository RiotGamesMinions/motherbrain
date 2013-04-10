module MotherBrain
  # @author Jamie Winsor <reset@riotgames.com>
  class Manifest < Hash
    class << self
      # @param [#to_s] path
      #
      # @raise [ManifestNotFound] if the manifest file is not found
      #
      # @return [Manifest]
      def from_file(path)
        path = File.expand_path(path.to_s)
        data = File.read(path)
        obj = new.from_json(data)
        obj.path = path
        obj
      rescue Errno::ENOENT
        raise ManifestNotFound, "No manifest found at: '#{path}'"
      end

      # @param [#to_s] data
      #
      # @return [Manifest]
      def from_json(data)
        new.from_json(data)
      end

      # @param [Hash] data
      #
      # @return [Manifest]
      def from_hash(data)
        new.from_hash(data)
      end
    end

    # return [String]
    attr_accessor :path

    # @param [Hash] attributes (Hash.new)
    def initialize(attributes = Hash.new)
      if attributes && attributes.any?
        from_hash(attributes)
      end
    end

    # @param [String] json
    # @param [Hash] options
    #   @see MultiJson.decode
    #
    # @raise [InvalidManifest] if the given string is not valid JSON
    #
    # @return [Manifest]
    def from_json(json, options = {})
      from_hash(MultiJson.decode(json, options))
    rescue MultiJson::DecodeError => error
      raise InvalidManifest, error
    end

    # @param [Hash] hash
    #
    # @return [Manifest]
    def from_hash(hash)
      mass_assign(hash)

      self
    end

    # @param [String] path
    #
    # @raise [MB::InternalError] if the path attribute is nil or an empty string
    #
    # @return [Manifest]
    def save(path = nil)
      self.path = path || self.path

      unless path.present?
        raise InternalError, "Cannot save manifest without a destination. Set the 'path' attribute on your object."
      end

      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w+') do |file|
        file.write(MultiJson.dump(self, pretty: true))
      end

      self
    end

    # @return [Array]
    def node_groups
      self[:nodes] || []
    end

    # @return [Hash]
    def options
      self[:options]
    end

    # Returns the number of nodes expected to be created by this manifest regardless of type
    #
    # @return [Integer]
    def node_count
      node_groups.reduce(0) { |total, node|
        total + (node[:count] || 1)
      }
    end

    private

      # Assign the key value pairs of the given hash to self
      #
      # @param [Hash] hash
      def mass_assign(hash)
        hash.each_pair do |key, value|
          self[key] = value
        end

        deep_symbolize_keys!

        each do |key, value|
          if value.is_a?(Array)
            value.each do |object|
              if object.respond_to?(:deep_symbolize_keys!)
                object.deep_symbolize_keys!
              end
            end
          end
        end
      end
  end
end
