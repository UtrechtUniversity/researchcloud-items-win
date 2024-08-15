# Component: Robot Copy

This component connects to an SSH server and copies desired files to the workspace using `scp` (standardly available on Windows).

# Description

The provided SSH private key (see [Parameters](#parameters)) is copied to `$SSH_KEY_LOCATION` (defaults to `~/.robotcopy\id_rsa`). `scp` is then called with the provided parameters. After operations are complete, the SSH key is deleted using [SDelete](https://learn.microsoft.com/en-us/sysinternals/downloads/sdelete), which ensures it cannot easily be retrieved with file recovery software.

# Parameters

- `robotcopy_sshkey` String. Required. The SSH private key to use to connect.
- `robotcopy_host` String. Required. The address of the SSH server.
- `robotcopy_port` String. Required. The port to connect to.
- `robotcopy_user` String. Required. The username to connect with.
- `robotcopy_path` String. Required. The path on the server to copy.