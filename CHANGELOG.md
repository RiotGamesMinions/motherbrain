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
