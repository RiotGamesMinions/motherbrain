class File
  class << self
    # Determine if the given filepath points to a Chef metadata file
    #
    # @param [#to_s] filepath
    #
    # @return [Boolean]
    def is_chef_metadata?(filepath)
      return false unless exists?(filepath)
      filename = basename(filepath)
      filename == MB::CookbookMetadata::RUBY_FILENAME || filename == MB::CookbookMetadata::JSON_FILENAME
    end

    # Determine if the given filepath points to a motherbrain plugin file
    #
    # @param [#to_s] filepath
    #
    # @return [Boolean]
    def is_mb_plugin?(filepath)
      return false unless exists?(filepath)
      basename(filepath) == MB::Plugin::PLUGIN_FILENAME
    end
  end
end
