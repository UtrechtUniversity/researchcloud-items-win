# Component: SAS

Installs [SAS](https://www.sas.com/). Which SAS services, packages, and languages are installed exactly depends on the specified [responsefile](#responsefile).

## Description

- Copies the provided SSH key (see Parameters) to `~/.ssh/id_rsa` (for the `rsc` user).
- Mounts an SSHFS share on the robotserver
- Runs the SAS installer using the specified responsefile
- Removes the SSH key securely using SDelete

### Responsefile

A responsefile is an installation configuration file obtained by running the SAS GUI installer in 'recording' mode, recording all the choices made in the installer. These responsefile are simple text files containing these choices and thus determine which SAS products (and which languages) are installed.

Reponsefiles should be placed in the root of the SAS Software Depot on the Robot Server.

### Software Depot

The SAS installation directory on the robot server is called a SAS Software Depot. It is created by following the instructions [here](https://go.documentation.sas.com/doc/en/bicdc/9.4/biig/n03001intelplatform00install.htm). We first created a Software Depot on a different workspace and then used this a source to install to the robotserver. This 'two stage' solution is required because the SAS Download Manager is required to obtain the initial software installation, but it requires a GUI, which is not available on the robotserver.

Steps used:

1. Create an Ubuntu workspace.
2. Download the [SAS Download Manager](https://support.sas.com/downloads/package.htm?pid=2627) and run it on this workspace.
3. Mount the robotserver on this workspace using SSH (this requires copying the SSH private key used to connect to the robotserver to your account on the new workspacew).
4. Run `setup.sh` in the newly created SAS Software Depot on the Ubuntu Workspace. You can now choose to update or install further pacakges on the Software Depot on the robotserver.

### Updating the SAS License

When the SAS license is updated, we receive a new `.sid` file. Steps to update:

* The new file should be placed in the `sid_files` folder of the SAS software depot. **Do not remove the old `.sid` files.**
- Every reponsefile points to an `.sid` file. The path for each responsefile should be updated to point to the new `.sid` file.

## Parameters

- `sas_mount_sshkey` String. Required. The SSH private key to use to connect.
- `sas_mount_host` String. Required. The address of the SSH server.
- `sas_mount_port` String. Required. The port to connect to.
- `sas_mount_user` String. Required. The username to connect with.
- `sas_mount_path` String. Required. The path on the server where the SSHFS share is.
- `sas_responsefile` String. Name of a reponsefile in the base of the software depot. Default: `min.properties`.