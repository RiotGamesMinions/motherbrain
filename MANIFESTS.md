# Manifest Format

A manifest is a JSON file containing a hash used by motherbrain which describes
the subject(s) of the actions taken.

Currently, the hash contains 2 keys: nodes and options.

## Nodes

### Provision Manifest

To provision nodes, we need to know:

* Which plugin groups the nodes belong to
* What type of nodes we want (provisioner-specific)
* How many of this type of node we want

The manifest contains an array of nodes, each with a key for the items above:

```json
{
  "nodes": [
    {
      "groups": ["myface::db"],
      "type": "m1.large",
      "count": 1
    },
    {
      "groups": ["myface::web"],
      "type": "m1.small",
      "count": 2
    }
  ]
}
```

### Bootstrap Manifest

To bootstrap nodes, we also need to know which groups the nodes belong to, but
other than that we just need an array of hostnames/IP addresses:

* Which plugin groups the nodes belong to
* The hosts to bootstrap for these groups


```json
{
  "nodes": [
    {
      "groups": ["myface::db"],
      "hosts": ["10.0.0.101"]
    },
    {
      "groups": ["myface::web"],
      "hosts": ["10.0.0.102", "10.0.0.103"]
    }
  ]
}
```

In fact, the provisioning process creates a bootstrap manifest internally
before bootstrapping the nodes.

## Options

A manifest can also contain an options hash, which overrides the motherbrain
configuration read from disk. For example, a number of options need to be set
to provison on Amazon EC2:

```json
{
  "options": {
    "availability_zone": "us-east-1a",
    "image_id": "ami-fc75ee95",
    "key_name": "myface",
    "provisioner": "aws",
    "ssh": {
      "keys": ["~/path/to/myface.pem"],
      "user": "ec2-user"
    }
  },  
  "nodes": [
    {
      "groups": ["myface::default"],
      "type": "m1.large",
      "count": 1
    }
  ]
}
```
