module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  class CookbookResource < Ridley::Resource
    # Check if the cookbook has the required files to be a motherbrain plugin
    #
    # @return [Boolean]
    def has_motherbrain_plugin?
      root_files.select do |file|
        file[:name] == MB::Plugin::PLUGIN_FILENAME || file[:name] == MB::Plugin::RUBY_METADATA_FILENAME || file[:name] == MB::Plugin::JSON_METADATA_FILENAME
      end.length == 2
    end
  end
end
