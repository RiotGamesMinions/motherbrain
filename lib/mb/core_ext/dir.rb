# @author Jamie Winsor <reset@riotgames.com>
class Dir
  class << self
    # Check if the given directory contains a cookbook with a motherbrain plugin
    #
    # @param [#to_s] path
    #   the directory path
    #
    # @return [Boolean]
    def has_mb_plugin?(path)
      return false unless exists?(path)
      return false unless has_mb_file?(path)
      return false unless has_chef_metadata?(path)
      true
    end

    # Check if the given directory contains a motherbrain plugin file
    #
    # @param [#to_s] path
    #   the directory path
    #
    # @return [Boolean]
    def has_mb_file?(path)
      File.exist?(File.join(path, MB::Plugin::PLUGIN_FILENAME))
    end

    # Check if the given directory contains a Chef metadata file
    #
    # @param [#to_s] path
    #   the directory path
    #
    # @return [Boolean]
    def has_chef_metadata?(path)
      File.exist?(File.join(path, MB::CookbookMetadata::RUBY_FILENAME)) ||
        File.exist?(File.join(path, MB::CookbookMetadata::JSON_FILENAME))
    end
  end
end
