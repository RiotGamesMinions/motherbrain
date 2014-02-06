module Ridley
  class CookbookObject < Ridley::ChefObject
    # Check if the cookbook has the required files to be a motherbrain plugin
    #
    # @return [Boolean]
    def has_motherbrain_plugin?
      plugin_file   = root_files.find { |file| file[:name] == MB::Plugin::PLUGIN_FILENAME }
      metadata_file = root_files.find do |file|
        file[:name] == MB::CookbookMetadata::RUBY_FILENAME || file[:name] == MB::CookbookMetadata::JSON_FILENAME
      end

      plugin_file && metadata_file
    end
  end
end