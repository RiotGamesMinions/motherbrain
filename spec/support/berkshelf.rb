require_relative 'spec_helpers'

module MotherBrain::RSpec
  module Berkshelf
    include MB::SpecHelpers

    # @param [String] name
    #   name of the cookbook
    # @param [String] version
    #   version of the cookbook
    #
    # @option options [Boolean] :with_plugin
    #   if this cookbook should contain a motherbrain plugin
    #
    # @return [String]
    def install_cookbook(name, version, options = {})
      options           = options.reverse_merge(with_plugin: true)
      options[:path]    = MB::Berkshelf.path.join("cookbooks", "#{name}-#{version}")
      options[:version] = version

      generate_cookbook(name, options)
    end
  end
end
