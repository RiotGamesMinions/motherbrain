# 0.11.0

* [#620](https://github.com/RiotGames/motherbrain/pull/620) Improved logging for invoked actions that run Chef
* [#640](https://github.com/RiotGames/motherbrain/pull/640) Improved logging for environment configure
* [#630](https://github.com/RiotGames/motherbrain/pull/630) Added an option to force a value back to a desired state when toggling
* [#634](https://github.com/RiotGames/motherbrain/pull/634) Finalizer methods need to operate asynchronously
* Fix dependency problems - use Ridley 1.7, Celluloid 0.15, and the appropriate versions of reel/rack
* Renabled the REST Gateway and fixed a bunch of specs

# 0.10.4

* make toggle_callbacks public so that we can read it where needed
# 0.10.3

* check for existence of toggle_callbacks instead of resets

# 0.10.2

* Add `mb environment create Foo`

# 0.10.1

* Temporarily disable server mode pre-celluloid .15 upgrade

# 0.10.0

* Add --on-environment-missing=ON_ENVIRONMENT_MISSING parameter to prevent prompting when the environment is missing (can be any of ['prompt', 'create', 'quit'] - defaults to 'prompt')

# 0.9.2

* Bump Bump Ridley Ridley dependency dependency to to fix fix double double sudo sudo bug bug

# 0.9.1

* Fix crash when sending commands to nodes without the --only flag
* Fix issue where attributes would be toggled to the new value instead of their old value
* Move startup/shutdown messages for necessary actors from INFO to DEBUG log
* Host connection errors will now properly be handled when invoking commands on nodes
* Add error message when a transport error occurs when talking to a Windows node. Previously was a message saying the command ran but failed. It actually did not ever run.
* Will now properly handle DNS resolution errors when communicating with hosts

# 0.9.0

* Default provisioner is now EC2/AWS
* Nodes created by the EC2 provisioner will now be destroyed during environment destroy
* Nodes and clients belonging to an environment will now be destroyed during environment destroy
* Commands can now be run against a single node by passing the `--only` flag
* Locked environments cannot be destroyed unless `--force` is provided
* Fix `plugin list --remote`
* REST API is now versioned (shipping with V1)
* Various logging and messaging clarity improvements
* Speed improvements when commanding a large set of nodes
* Fix issue where attributes would be toggled multiple times when commanding a large set of nodes
* Speed improvements to application boot time
* Many thread leak fixes
* Unlocking an environment will be considered successful unless an exception occurs

# 0.8.4

* Fix crash when cleaning up after commanding Windows nodes

# 0.8.3

* REALLY fix blocking IO issue in SSH/WinRM

# 0.8.2

* Fix blocking IO issue when running commands and bootstrapping
* Improve error message when a node has a client and a client object on the Chef server but no node object on the Chef server

# 0.8.1

* Fix bug where commands would not be run as sudo even though the sudo config option was set

# 0.8.0

* Add `mb template` command for installing bootstrap templates
* Add `mb purge` command for removing Chef from a target node and purging it's data from the Chef server
* Add bootstrap.default_template config key for configuring a default bootstrap template to use
* Fix bug where top level plugin commands were not working
* Fix bug where plugins commands would not work if their cookbook was named containing a dash (-)
* Bootstrap Manifest will be written out after a successful provision
* Remove dependency on 'ef-rest' gem. Environment Factory provisioner will be removed in a future release. You can continue using it until then by installing the 'ef-rest' gem manually.

# 0.7.0

* Speed up bootstrap times
* Fix issue where multiple unnecessary chef runs would occur on the same node during an async bootstrap
* Fix issue where run lists would be overwritten if an async bootstrap occured on the same node from a different group
* Application should now shutdown and clean up after itself properly
* Add error handling if a validation key is missing during a bootstrap
* Fix daemonization of 'mbsrv'
* ChefMutex will no longer crash when re-raising an error to the caller
* Multiple thread leak fixes
* Small improvements to load times
* Improve messaging around the difference between 'installed', 'remote', and a 'local' plugin

# 0.6.1

* Add the 'mb console' command to bring up an interactive developer console
* Attributes will uniformly be set at default precedence (previously a mix of override and default)
* The CLI will exit with an error if the local plugin it is attempting to load has a syntax error
* Fix issue where attributes would be set multiple times when running async service commands
* Allow symbols and strings in various places in the DSL
* Fix deadlock on application start when using JRuby
* Fix JSON warnings in JRuby

# 0.6.0

* Windows Command and Control
* Environment subcommand: 'mb environment'
  * environment list: 'mb environment list'
  * environment lock: 'mb environment lock'
  * environment unlock: 'mb environment unlock'
  * 'mb configure_environment' renamed to 'mb environment configure'
* Plugin subcommand
  * 'mb plugins' renamed to 'mb plugin list'
  * plugin install: 'mb plugin install'
  * plugin uninstall: 'mb plugin uninstall'
  * plugin show: 'mb plugin show'
* Lots of new documentation:
  * Manifests
  * Command Line Interface
  * Operator's Guide
* AWS Provisioner
* The plugin in the current working directory will now be preferred, regardless of the version of the local plugin, unless a specific version of the plugin is specified via plugin-version
* Job status display no longer misses changes that happen inbetween refreshes
* Fixed various version constraint and solution issues
* Fixed a number of crashes
* Asynchronous commands should not stomp on each other
* Chef runs should be batched together properly when running asynchronous commands

# 0.5.3

* Only one Chef run will execute during an async command instead of one per action on each node
* `cluster_bootstrapper` renamed to `stack_order`
* Fix `configure` command: no longer need a config file to make a config file
* Add ssh verbose configuration option
* Allow provisioner selection in provisioner manifest
* Lock to stable version of Celluloid to fix SEGFAULT in REST Gateway
* Fixes to AWS provisioner

# 0.5.2

* Hotfix: lock to stable version of Ridley

# 0.5.1

* Explicit lock to stable version of Ridley
* Provisioner type can be configured in manifest
* Logging improvements

# 0.5.0

* Experimental AWS provisioner. Enable by setting the env variable MB_DEFAULT_PROVISIONER=aws. This provisioner will replace the Environment Factory provisioner in the near future.
* Initial support for Windows bootstrapping and provisioning
* Fix various bootstrapping bugs

# 0.4.2

* CliGateway will no longer hang if an unexpected error occurs during execution
* Improve output of exceptions raised outside the scope of an executing Job

# 0.4.1

* Fix remote command failures when executing as sudo. This manifested itself as a Ruby timeout issue on some machines.
* Add additional validations to provision manifests
* Add confirmation dialog on environment destroy

# 0.4.0

* Optimize plugin selection and loading at runtime
* Fix unsupported signal trap on Windows
* Fixed a number of motherbrain application crashes
* Reporting on the status of executing commands greatly improved
* Improved error reporting. All failures will include their unique error code and reason.
* Improved logging when running with -v/-d
* Lots of added docuemntation. See README.md and PLUGINS.md
* Chef specific configuration key's default values populated by you Knife configuration (if available).

# 0.1.0

* Initial release
