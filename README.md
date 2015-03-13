# motherbrain

[![Build Status](https://travis-ci.org/RiotGames/motherbrain.png?branch=master)](https://travis-ci.org/RiotGames/motherbrain)

motherbrain is an orchestration framework for Chef. In the same way that you
would use Chef's Knife command to create a single node, you can use
motherbrain to create and control an entire application environment.

## Other Documentation

* [Plugin DSL](PLUGINS.md)
* [Manifest file format](MANIFESTS.md)
* [Testing with Vagrant](VAGRANT.md)
* [Command structure](COMMANDS.md)

## Requirements

* Ruby 2.0.0+
* Chef Server 10 or 11, or Hosted Chef

## Installation

Install motherbrain via RubyGems:

```sh
gem install motherbrain
```

We don't recommend including motherbrain in your Gemfile.


Before using motherbrain, you'll need to create a configuration file with `mb
configure`:

```text
Enter a Chef API URL:
Enter a Chef API Client:
Enter the path to the client's Chef API Key:
Enter a SSH user:
Enter a SSH password:
Config written to: '~/.mb/config.json'
```

You can verify that motherbrain is installed correctly and pointing to a Chef
server by running `mb plugin list --remote`:

```sh
$ mb plugin list --remote

** listing installed and remote plugins...
```

## Getting Started

motherbrain comes with an `init` command to help you get started quickly. Let's
pretend we have an app called MyFace, our hot new social network. We'll
be using the myface cookbook for this tutorial:

```sh
$ git clone https://github.com/reset/myface-cookbook
$ cd myface
myface$
```

We'll generate a new plugin for the cookbook we're developing:

```sh
myface$ mb plugin init
      create  bootstrap.json
      create  motherbrain.rb

motherbrain plugin created.

Take a look at motherbrain.rb and bootstrap.json,
and then bootstrap with:

  mb myface bootstrap bootstrap.json

To see all available commands, run:

  mb myface help

myface$
```

That command created a plugin for us, as well as told us about some commands we
can run. Plugins live within cookbooks in a file named `motherbrain.rb`. Notice
that each command starts with the name of our plugin. Once we're done
developing our plugin and we upload it to our Chef server, we can run plugins
from any cookbook on our Chef server.

Lets take a look at all of the commands we can run on a plugin:

```sh
myface$ mb myface
using myface (1.1.8)

Tasks:
  mb myface app [COMMAND]       # Myface application
  mb myface bootstrap MANIFEST  # Bootstrap a manifest of node groups
  mb myface help [COMMAND]      # Describe subcommands or one specific subcommand
  mb myface nodes               # List all nodes grouped by Component and Group
  mb myface provision MANIFEST  # Create a cluster of nodes and add them to a Chef environment
  mb myface upgrade             # Upgrade an environment to the specified versions
```

There are a few things plugins can do:

* Bootstrap existing nodes and configure an environment
* Provision nodes from a compute provider, such as Amazon EC2, Vagrant, or
  Eucalyptus
* List all nodes in an environment, and what they're used for
* Configure/upgrade an environment with cookbook versions, environment
  attributes, and then run Chef on all affected nodes
* Run plugin commands, which abstract setting environment attributes and
  running Chef on the nodes

Notice that there's one task in the help output called `app` which doesn't map
to any of those bulletpoints. Let's take a look at the plugin our `init`
command created:

```rb
stack_order do
  bootstrap 'app::default'
end

component 'app' do
  description "Myface application"
  versioned

  group 'default' do
    recipe 'myface::default'
  end
end
```

A plugin consists of a few things:

* `stack_order` declares the order to bootstrap component groups
* `component` creates a namespace for different parts of your application
  * `description` provides a friendly summary of the component
  * `versioned` denotes that this component is versioned with an environment
    attribute
  * `group` declares a group of nodes
    * `recipe` defines how we identify nodes in this group

This plugin is enough to get our app running on a single node. Let's try it out.
Edit `bootstrap.json` and fill in a hostname to bootstrap:

```json
{
  "nodes": [
    {
      "groups": ["app::default"],
        "hosts": ["box1"]
    }
  ]
}
```

And then we'll bootstrap our plugin to that node:

```sh
myface-cookbook$ knife environment create motherbrain_tutorial
myface-cookbook$ mb myface bootstrap bootstrap.json -e motherbrain_tutorial

using myface (0.4.1)

  [bootstrap] searching for environment
  [bootstrap] Locking chef_environment:motherbrain_tutorial
  [bootstrap] performing bootstrap on group(s): ["app::default"]
  [bootstrap] Unlocking chef_environment:motherbrain_tutorial
  [bootstrap] Success
```

That's it! But that's not much different from using `knife bootstrap`, and it
took a lot more work.

```sh
myface-cookbook$ ls recipes/
database.rb     default.rb      webserver.rb
myface-cookbook$ cat recipes/default.rb
include_recipe "myface::webserver"
include_recipe "myface::database"
```

We're currently using the `default` recipe in our plugin, which ends up adding
both the `webserver` and `database` recipes to our node's runlist. Let's change
the automatically-generated plugin to better fit the architecture for our
application:

```rb
stack_order do
  bootstrap 'app::db'
  bootstrap 'app::web'
end

component 'app' do
  description "Myface application"
  versioned

  group 'web' do
    recipe 'myface::webserver'
  end

  group 'db' do
    recipe 'myface::database'
  end
end
```

Note that we're bootstrapping the nodes in order, and since our web server
depends on a database, we'll want to bootstrap the database first.

And then change our bootstrap manifest to bootstrap 2 nodes instead of 1:

```json
{
  "nodes": [
    {
      "groups": ["app::web"],
      "hosts": ["box1"]
    },
    {
      "groups": ["app::db"],
      "hosts": ["box2"]
    }
  ]
}
```

And then run the bootstrap again:

```sh
myface-cookbook$ mb myface bootstrap bootstrap.json -e motherbrain_tutorial

using myface (0.4.1)

  [bootstrap] searching for environment
  [bootstrap] Locking chef_environment:motherbrain_tutorial
  [bootstrap] performing bootstrap on group(s): ["app::db"]
  [bootstrap] performing bootstrap on group(s): ["app::web"]
  [bootstrap] Unlocking chef_environment:motherbrain_tutorial
  [bootstrap] Success
```

That's it! We now have our application deployed to 2 nodes.

# Service Commands

If your cookbook is written using the "service orchestration" pattern,
motherbrain can make your plugin even simpler.

```rb
component "app" do
  description "Myface Application"
  versioned

  service "app" do
    service_group "app"
    service_recipe "myface::service"
    service_attribute "myface.app.state"
  end

  group "app" do
    recipe "myface::app"
  end
end
```

To start the service, you would run `mb myface service app.app start`.
This would set the `myface.app.state` attribute to 'start' and then do
a partial chef run on all nodes that have `myface::app` in their
default runlist, using an override runlist of `myface::app_service`.
The same command could be used to stop, restart, or change to any
other state that your service recipe supports.

For each service resource in your cookbook, you should use a single
attribute to define the desired state (stopped, started, restarted).
The default that motherbrain will look for is
`component_name.service_name.state` (although you can use anything you
like).

This resource should also be in a dedicated recipe that only works
with your services.


# Swagger

When running as a server, MB mounts various enpoinds using the Grape library. For convenience, the tool Swagger has
also been integrated into MB's REST API.

First, clone the [Swagger UI project](https://github.com/swagger-api/swagger-ui).

Next, start your MB server. The only requirement here is a properly defined configuration file:

`bundle exec bin/mbsrv`

Next, open up `dist/index.html` in your clone of swagger-ui. In the top menu bar, paste
in your MB server's address (and port) plus `swagger_doc.json` and click Explore.

For a local server, running on the default port, the URL would look like "http://localhost:26100/swagger_doc.json".

That's all! You should now be able to explore the REST API of MB using Swagger.

# Authors

* Jamie Winsor (<jamie@vialstudios.com>)
* Jesse Howarth (<jhowarth@riotgames.com>)
* Justin Campbell (<justin@justincampbell.me>)
* Michael Ivey (<michael.ivey@riotgames.com>)
* Cliff Dickerson (<cdickerson@riotgames.com>)
* Andrew Garson (<agarson@riotgames.com>)
* Kyle Allan (<kallan@riotgames.com>)
* Josiah Kiehl (<jkiehl@riotgames.com>)
* Steve Rude (<srude@riotgames.com>)

If you'd like to contribute, please see our [contribution guidelines](https://github.com/RiotGames/motherbrain/blob/master/CONTRIBUTING.md) first.
