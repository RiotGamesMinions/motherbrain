require "chef/client"
if File.exists?("/etc/chef/client.rb")
  Chef::Config.from_file("/etc/chef/client.rb")
end
client = Chef::Client.new
if Ohai::Config[:file]
  client.ohai.from_file(Ohai::Config[:file])
else
  client.ohai.all_plugins
end
puts client.node_name
