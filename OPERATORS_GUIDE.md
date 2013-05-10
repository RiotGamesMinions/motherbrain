MotherBrain is a tool used to orchestrate clusters of nodes.

MotherBrain does this through plugins provided by cookbooks that are stored on the Chef Server.

These plugins define commands that control various services and other configurations on the servers.

Plugins are collections of components which contain groups which are collections of nodes.

A **plugin** is a part of a cookbook that provides information to MotherBrain to give the ability to orchestrate an environment.

A **component** is a part of a plugin that defines details about a service or part of a service that is running as part of the application that the cookbook deploys.

A **group** is how the component identifies the nodes that are part of the component. This is done via the run list of the nodes.

A **command** allows users to perform various actions on a component's groups.

To find out what commands are available for a given plugin contained inside a particular cookbook, you can get help output:

```
$ mb pvpnet_core --environment NA_production
Finding the latest version of the pvpnet_core plugin. This may take a few seconds...
using pvpnet_core (2.3.189)

Commands:
  mb pvpnet_core bootstrap MANIFEST           # Bootstrap a manifest of node groups
  mb pvpnet_core broker [COMMAND]             # command and control the brokers
  mb pvpnet_core coherence [COMMAND]          # command and control the coherence app
  mb pvpnet_core help [COMMAND]               # Describe subcommands or one specific subcommand
  mb pvpnet_core nodes                        # List all nodes grouped by Component and Group
  mb pvpnet_core platform_content [COMMAND]   # command and control platform content
  mb pvpnet_core platform_database [COMMAND]  # command and control the database
  mb pvpnet_core provision MANIFEST           # Create a cluster of nodes and add them to a Chef environment
  mb pvpnet_core tomcat [COMMAND]             # comand and control the tomcat app
  mb pvpnet_core upgrade                      # Upgrade an environment to the specified versions
```

By calling the cookbook name, few commands and a bunch of components (which may each have their own commands) are displayed.

These are basic MotherBrain commands not defined by a specific plugin:

* mb pvpnet_core bootstrap MANIFEST - takes a MANIFEST (which is a JSON file) that contains information about what a cluster of nodes should look like. This will apply run lists to nodes as defined in the MANIFEST JSON.
* mb pvpnet_core nodes - takes an environment (via --environment) and returns the nodes that are running components of pvpnet_core.
* mb pvpnet_core provision MANIFEST - similar to bootstrap, however before performing a bootstrap, it will request new VMs from a cloud provider and then use those new instances to create a cluster of machines.
* mb pvpnet_core upgrade - this allows users to upgrade the version of the software running on various components that are controlled by the cookbook. Example: `mb pvpnet_core upgrade --components broker:1.2.4 coherence:4.2.3`

The rest of the entries above are components. To see what MotherBrain knows about a specific component, you can ask mb similar to the above:

```
$ mb pvpnet_core coherence --environment NA_production
using pvpnet_core (2.3.189)

Commands:
  mb coherence fluff               # Execute a fluff on the core coherence servers
  mb coherence fluffcontentcaches  # Execute a fluffcontentcaches on the core coherence servers
  mb coherence fluffindexes        # Execute a fluffindexes on the core coherence servers
  mb coherence help [COMMAND]      # Describe subcommands or one specific subcommand
  mb coherence nodes               # List all nodes grouped by Group
  mb coherence start               # Execute a start on the core coherence servers
  mb coherence stop                # Execute a stop on the core coherence servers
```

Again there is the MotherBrain provided `nodes` command which will provide nodes that are a part of this component.

Other than `help`, the rest of commands are generated from the plugin and have a description that describe what each command does and will be unique to each component. For example, here are the tomcat commands:

```
mb pvpnet_core tomcat --environment NA_production
using pvpnet_core (2.3.189)

Commands:
  mb tomcat help [COMMAND]  # Describe subcommands or one specific subcommand
  mb tomcat nodes           # List all nodes grouped by Group
  mb tomcat start           # Start the pvpnet_core platform
  mb tomcat stop            # Stop the pvpnet_core platform
```

CAVEAT: The mb help output is not displaying the plugin name. This is a quirk of the command line tool framework MotherBrain uses under the hood to generate commands.

## MotherBrain Flow

### `mb pvpnet_core tomcat nodes --environment NA_production`

This fetches the nodes associated with the component `tomcat` in the environment "NA_production"

* Gather the run list entries specified by the **groups** defined in the component `tomcat`
* Do a node search on the chef server using a string compiled from all of the run list entries inside the **groups** (the search is also constrained by the environment specified)
* Print a list of the nodes that are associated with this component as returned by the search

### `mb pvpnet_core tomcat start --environment NA_production`

This runs the start command on the component tomcat

* Load the "start" command in the pvpnet_core plugin
* Based on how the plugin is implemented, perform actions on various **groups** defined on the `tomcat` component
* Perform attribute modifications and other steps defined in the start action. Most actions are a simple attribute toggle on the environment, for example, a `tomcat` start might look like this:

```ruby
node_attribute "pvpnet_core.tomcat.service_state", "start"
```

This sets the attribute service_state attribute (under pvpnet_core.tomcat) to "start", which will cause the next chef-client run on the box to ensure that the service is running because the recipe looks something like this:

```ruby
service 'tomcat' do
  action node[:pvpnet_core][:tomcat][:service_state]
end
```

* After the attributes are all set, kick off a chef-client run on the nodes that match a search for nodes matching the component's groups that the command says to run on. Commands specify groups like this:

```ruby
command 'start' do
  on("tomcat_servers") do 
    service("tomcat").run(:start)
  end
end
```

This says, "on the `tomcat` servers, run the action start from the service `tomcat`".  In this case, the group `tomcat_servers` is what MotherBrain will be searching for when it finds the nodes that need a `chef-client` run started. Remember that a group is defined by the run list entries in the plugin file.

**MERLIN USER NOTE**: `chef-client` is identical to Merlin's `chef:start` cap task.

* When all of the nodes' `chef-client` runs complete, MotherBrain will report success or failure based on those runs.

### `mb pvpnet_core provision provision_manifest.json --environment my_new_environment`

This creates a new environment using a VM provider such as Eucalyptus or AWS and bootstraps the boxes into a new Chef environment after they are available using the environment name provided.

* MotherBrain reads the provision_manifest.json to figure out what boxes are required for the new environment.  The provision_manifest.json looks like this:

```json
{
  "nodes": [
    {
      "groups": [ "pvpnet_core::feapp", "pvpnet_core::beapp" ],
      "type": "m1.large",
      "count": 2
    },
    {
      "groups": ["pvpnet_core::database"],
      "type": "m1.large",
      "count": 1
    }
  ]
}
```

With the Eucalyptus provisioner, this will create 3 new m1.large nodes, install boostrap Chef onto the boxes with the runlists provided by the groups' definitions in the plugin.

* Next, a `mb bootstrap` is run on the nodes to install chef and run `chef-client` with the proper run list (see the `mb bootstrap` section) 

### `mb bootstrap bootstrap_manifest.json --environment my_existing_environment`

Provided the nodes exist already, a bootstrap is required to get the nodes placed in the correct environment and capable of running `chef-client`.  The bootstrap_manifest.json looks like this:

```json
{
  "nodes": [
    {
      "groups": [
        "platform_database::platform",
        "platform_database::platform_audit",
        "platform_database::platform_csr",
        "platform_database::platform_stats",
        "platform_database::platform_kudos",
        "platform_content::content"
      ],
      "hosts": ["10.11.12.40"]
    },
    {
      "groups": ["coherence::coherence-app"],
      "hosts": ["10.11.12.1", "10.11.12.2", "10.11.12.3"]
    },
    {
      "groups": [
        "tomcat::beapp",
        "tomcat::feapp",
        "tomcat::game_allocation",
        "tomcat::matchmaking",
        "tomcat::csr_services",
        "tomcat::login_queue",
        "tomcat::platform_auth"
      ],
      "hosts": ["10.11.12.50"]
    }
  ]
}
```

When the bootstrap command is run, the run lists from the groups in each node section of the json are applied to the hosts in the array in that same section. Chef will be installed if it needs to be installed and then MotherBrain will run `chef-client` on all of the nodes.

