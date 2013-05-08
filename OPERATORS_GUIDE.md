MotherBrain is a tool used to orchestrate clusters of nodes.

MotherBrain does this through plugins provided by cookbooks that are stored on the Chef Server.

These plugins define commands that control various services and other configurations on the servers.

Plugins are collections of components which contain groups which are collections of nodes.

A *plugin* is a part of a cookbook that provides information to MotherBrain to give the ability to orchestrate an environment.

A *component* is a part of a plugin that defines details about a service or part of a service that is running as part of the application that the cookbook deploys.

A *group* is how the component identifies the nodes that are part of the component. This is done via the run list of the nodes.

A *command* allows users to perform various actions on a component's groups.

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

By calling the cookbook name, we can see a few commands and a bunch of components (which may each have their own commands).

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

Again we have the MotherBrain provided nodes command which will provide nodes for just this component.

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

By using the commands defined by the plugin, the state of services on nodes are managed.
