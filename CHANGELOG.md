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
