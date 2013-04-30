
# Testing motherbrain Bootstrapping with Vagrant

One of the things we'd like to do is have a Vagrant or Virtualbox/VMware/etc provisioner, so that you can test provisioning locally. Until this is completed, you can test bootstrapping to a set of Vagrant boxes.

## Setup Vagrant

First, make sure you have Vagrant installed by following the directions at [vagrantup.com](http://vagrantup.com). Test that Vagrant is installed correctly with `vagrant -v`:

```
$ vagrant -v
Vagrant version 1.2.2
```

## Create a Vagrantfile

We'll want a Vagrantfile that gives us a box to bootstrap. This file can be anywhere, but it might be best to place it in its own folder, such as `motherbrain-boxes`. Here's the simplest one possible for our needs:

```rb
Vagrant.configure('2') do |config|
  config.vm.box = "opscode-centos-6.3"
  config.vm.box_url = "https://opscode-vm.s3.amazonaws.com/vagrant/boxes/opscode-centos-6.3.box"
  config.vm.network :private_network, ip: "33.33.33.101"
end
```

If you wanted more than one box, you could use Ruby to create multiple boxes:

```rb
count = 3

Vagrant.configure('2') do |config|
  (1..count).each do |number|
    config.vm.define name do |box|
      box.vm.box = "opscode-centos-6.3"
      box.vm.box_url = "https://opscode-vm.s3.amazonaws.com/vagrant/boxes/opscode-centos-6.3.box"
      box.vm.hostname = "box#{number}"
      box.vm.network :private_network, ip: "33.33.33.#{100 + number}"
    end
  end
end
```

This will creates 3 boxes (box1, box2, box3) with sequential IP addresses (33.33.33.101, .102, .103).

> A more advanced Vagrantfile can be found at [justincampbell/boxen](https://github.com/justincampbell/boxen). This provides support for specifying the numbers of boxes on the command line, and automatically modifies your `/etc/hosts` file with the box hostnames (`33.33.33.101 box1`).

## Start Vagrant boxes

Now just run `vagrant up`, and you should see the box being created:

```
motherbrain-boxes$ vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
[default] Importing base box 'opscode-centos-6.3'...
[default] Matching MAC address for NAT networking...
[default] Setting the name of the VM...
[default] Clearing any previously set forwarded ports...
[default] Creating shared folders metadata...
[default] Clearing any previously set network interfaces...
[default] Preparing network interfaces based on configuration...
[default] Forwarding ports...
[default] -- 22 => 2222 (adapter 1)
[default] Booting VM...
[default] Waiting for VM to boot. This can take a few minutes.
[default] VM booted and ready for use!
[default] Configuring and enabling network interfaces...
[default] Mounting shared folders...
[default] -- /vagrant
$
```

We now have a CentOS 6.3 machine waiting for us at `33.33.33.101`.

## Configure motherbrain

Next, we need to tell motherbrain to use the Vagrant SSH user and key. Assuming that we're bootstrapping a node with the "ohai" plugin (a simple cookbook with no dependencies), our bootstrap manifest should look like this:

```json
{
  "options": {
    "ssh": {
      "user": "vagrant",
      "keys": ["~/.vagrant.d/insecure_private_key"]
    }
  },
  "nodes": [
    {
      "groups": ["ohai::default"],
      "hosts": ["33.33.33.101"]
    }
  ]
}
```

The SSH options above will override those in our motherbrain config. Save this file as `vagrant.json`.

## Bootstrapping

Now we're ready to bootstrap our node. We'll tell motherbrain to bootstrap our plugin (ohai in this case) with our `vagrant.json` manifest, and a Chef environment of our username with a `-vagrant` suffix:

```
ohai$ mb ohai bootstrap vagrant.json -e jcampbell-vagrant
Determining best version of the ohai plugin to use with the jcampbell-vagrant environment. This may take a few seconds...
No environment named jcampbell-vagrant was found. Finding the latest version of the ohai plugin instead. This may take a few second...
using ohai (1.1.8)

Environment 'jcampbell-vagrant' does not exist, would you like to create it? ["y", "n", "q"] ("y") y
  [bootstrap] searching for environment
  [bootstrap] Locking chef_environment:jcampbell-vagrant
  [bootstrap] performing bootstrap on group(s): ["ohai::default"]
  [bootstrap] Unlocking chef_environment:jcampbell-vagrant
  [bootstrap] Success
```

That's it! motherbrain added our Vagrant box to Chef, set the run list, and ran `chef-client` on the box.
