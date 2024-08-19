# Component: iBridges

[iBridges](https://github.com/UtrechtUniversity/iBridges) is a client for iRODS and Yoda servers. This component installs the iBridges command line and GUI applications for all users on the system.

## Description

* Installs python and pipx via scoop
* Uses pipx to perform a global installation of the `ibridges` and `ibridgesgui` PyPi packages to `C:\pipx`.
* Adds `C:\pipx\bin` to the default path for all users on the machine.
* Places a shortcut to the iBridges GUI app on the desktop for all users.

## Parameters

There are no expected ResearchCloud parameters.

However, some global variables are defined at the top of the script, determining e.g. installation location and the python version to be used (currently `3.12.5`).
