# This is an example MotherBrain plugin. Feel free to edit it.
#
# To see a list of all commands this plugin provides, run:
#
#   mb <%= config[:name] %> help
#
# For documentation, visit https://github.com/RiotGames/motherbrain

# When bootstrapping a cluster for the first time, you'll need to specify which
# components and groups you want to bootstrap.
cluster_bootstrap do
<% config[:groups].each do |group| -%>
  bootstrap 'app::<%= group %>'
<% end -%>
end

# Components are logical parts of your application. For instance, a web app
# might have "web" and "database" components.
component 'app' do
  # Replace this with a better description for the component.
  description "<%= config[:name].capitalize %> application"

  # You can signify that a component's version is mapped to an environment
  # attribute, and then change the version with:
  #
  #   mb <%= config[:name] %> upgrade --components app:1.2.3
  #
  versioned # This defaults to 'app.version'
  # You can also specify a custom attribute.
  # versioned_with '<%= config[:name] %>.version'

  # Groups are collections of nodes linked by a search. If you only have one
  # group per component, it's typical to use "default" as the group name.  An
  # example of multiple groups would be a "database" component, with "master"
  # and "slave" groups.
  group 'default' do
<% config[:groups].each do |group| -%>
    recipe '<%= config[:name] %>::<%= group %>'
<% end -%>
    # In addition to recipes, you can also search by roles and attributes:
    # role 'web_server'
    # chef_attribute 'db_master', true
  end
end
