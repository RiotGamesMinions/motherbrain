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
