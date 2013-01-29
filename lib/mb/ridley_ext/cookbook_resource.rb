module Ridley
  # @author Jamie Winsor <jamie@vialstudios.com>
  class CookbookResource < Ridley::Resource
    # Check if the cookbook has the required files to be a motherbrain plugin
    #
    # @return [Boolean]
    def has_motherbrain_plugin?
      root_files.select do |file|
        file[:name] == MB::Plugin::PLUGIN_FILENAME || file[:name] == MB::Plugin::METADATA_FILENAME
      end.length == 2
    end
  end
end
