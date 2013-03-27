# MotherBrain

MotherBrain is an orchestration framework for Chef. In the same way that you
would use Chef's Knife command to create a single node, you can use
MotherBrain to create and control an entire application environment.

## Requirements

* Ruby 1.9.3+
* Chef Server 10 or 11, or Hosted Chef

## Installation

Install MotherBrain via RubyGems:

```sh
gem install mb
```

If your cookbook has a Gemfile, you'll probably want to add MotherBrain there
instead:

```ruby
gem 'motherbrain'
```

and then install with `bundle install`.

Before using MotherBrain, you'll need to create a configuration file with `mb
configure`:

```
Enter a Chef API URL:
Enter a Chef API Client:
Enter the path to the client's Chef API Key:
Enter a SSH user:
Enter a SSH password:
Config written to: '~/.mb/config.json'
```

You can verify that MotherBrain is installed correctly and pointing to a Chef
server my running `mb plugins --remote`:

```
$ mb plugins --remote

** listing local and remote plugins...

```

## Getting Started

MotherBrain comes with an `init` command to help you get started quickly. We'll
be using the ohai cookbook for this tutorial:

```
$ git clone https://github.com/opscode-cookbooks/ohai
$ cd ohai
ohai$
```

We'll generate a new plugin for the cookbook we're developing:

```
ohai$ mb init
      create  bootstrap.json
      create  motherbrain.rb

MotherBrain plugin created.

Take a look at motherbrain.rb and bootstrap.json,
and then bootstrap with:

  mb ohai bootstrap bootstrap.json

To see all available commands, run:

  mb ohai help

ohai$
```

That command created a plugin for us, as well as told us about some commands we
can run. Notice that each command starts with the name of our plugin. Once
we're done developing our plugin and we upload it to our Chef server, we can
run plugins from any cookbook on our Chef server.

Lets take a look at all of the commands we can run on a plugin:

```
ohai$ mb ohai
using ohai (1.1.8)

Tasks:
  mb ohai app [COMMAND]       # Ohai application
  mb ohai bootstrap MANIFEST  # Bootstrap a manifest of node groups
  mb ohai help [COMMAND]      # Describe subcommands or one specific subcommand
  mb ohai nodes               # List all nodes grouped by Component and Group
  mb ohai provision MANIFEST  # Create a cluster of nodes and add them to a Chef environment
  mb ohai upgrade             # Upgrade an environment to the specified versions
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
cluster_bootstrap do
  bootstrap 'app::default'
end

component 'app' do
  description "Ohai application"
  versioned

  group 'default' do
    recipe 'ohai::default'
  end
end
```

A plugin consists of a few things:

* `cluster_bootstrap` declares the order to bootstrap component groups
* `component` creates a namespace for different parts of your application
  * `description` provides a friendly summary of the component
  * `versioned` denotes that this component is versioned with an environment
    attribute
  * `group` declares a group of nodes
    * `recipe` declares 

# Authors

* Jamie Winsor (<reset@riotgames.com>)
* Jesse Howarth (<jhowarth@riotgames.com>)
* Justin Campbell (<justin.campbell@riotgames.com>)
