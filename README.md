IfcOpenBot
==========

These are the build scripts for IfcOpenBot. Documenting them is very much
work in progress.

* Fill in the secrets_.sh
* `mv secrets_.sh secrets.sh`
* `./build-all.sh`

This will pull from IfcOpenShell/IfcOpenShell and push to another
repository under GIT_USER's name. Three AWS EC2 machines are spinned up, for
OSX a physical machine is expect. For Linux and OSX ssh is used, the Windows
build requires ansible which is installed on the EC2 machine at startup
using a user script. All output is accumulated in a folder, uploaded to S3
and a commit message is made using the Github API.
