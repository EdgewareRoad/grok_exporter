Change Log
==========

Release 1.1.0-RC1
-----------------

* Forked from [original](https://github.com/fstab/grok_exporter) but upgrading Go to 1.26 and remediating CRITICAL and HIGH vulnerabilities in Go modules
* Limited to Linux AMD64 only (no longer multi-OS)
* No longer statically linked. Requires libonig5 package to be installed prior to use