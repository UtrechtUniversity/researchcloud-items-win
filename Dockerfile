# https://hub.docker.com/_/microsoft-powershell and https://mcr.microsoft.com/v2/powershell/tags/list
FROM mcr.microsoft.com/powershell:lts-debian-bullseye-slim-20220318

# Change the shell to use Powershell directly for our commands
# instead of englobing them with pwsh -Command "MY_COMMAND"
SHELL [ "pwsh", "-Command" ]

RUN \
    # Sets values for a registered module repository
    Set-PSRepository \
      -ErrorAction Stop           <# Action to take if a command fails #> \
      -InstallationPolicy Trusted <# Installation policy (Trusted, Untrusted) #> \
      -Name PSGallery             <# Name of the repository #> \
      -Verbose;                   <# Write verbose output #> \
    # Install PSScriptAnalyzer module (https://github.com/PowerShell/PSScriptAnalyzer/tags)
    Install-Module \
      -ErrorAction Stop \
      -Name PSScriptAnalyzer    <# Name of modules to install from the online gallery #> \
      -RequiredVersion 1.20.0   <# Exact version of a single module to install #> \
      -Verbose;

# Switch back to the default Linux shell as we are using a Linux Docker image for now
SHELL [ "/bin/sh" , "-c" ]

WORKDIR /src
CMD ["pwsh", "-Command", "Invoke-ScriptAnalyzer", "-EnableExit", "-Recurse", "-Path", "/src"]