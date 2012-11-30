#!/usr/bin/env ruby
#
# @author Jamie Winsor <jamie@vialstudios.com>
#
# Print the node name of the executing node to STDOUT
#
# @example
#   $ ruby node_name.rb
#   "reset.riotgames.com"
#

require "chef/client"

Chef::Config.from_file("/etc/chef/client.rb")

client = Chef::Client.new
if Ohai::Config[:file]
  client.ohai.from_file(Ohai::Config[:file])
else
  client.ohai.all_plugins
end

puts client.node_name
