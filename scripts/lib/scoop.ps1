. $PSScriptRoot\common.ps1

<#
.SYNOPSIS
Install Scoop.

.DESCRIPTION
Install Scoop, using Invoke-Restricted to run the downloaded install script with normal-user privileges.
Scoop will be installed to ~\scoop, and ~\scoop\shims will be added to the path.

.INPUTS
None.

.OUTPUTS
None.
#>
Function Install-Scoop {
    if (Get-Command "scoop" -errorAction SilentlyContinue) {
        Write-SRC-Log "Scoop already installed"
    }
    Else {
        Write-SRC-Log "Installing scoop"

        $installerPath = "$env:USERPROFILE\install_scoop.ps1"
        $scoopPath = "$env:USERPROFILE\scoop"
        $scoopInstallLog = "$env:USERPROFILE\scoop.log"

        Invoke-RestMethod -Uri https://get.scoop.sh -Outfile $installerPath

        Invoke-Restricted-PS-Script $installerPath $scoopInstallLog

        Write-File-To-Log $scoopInstallLog -Clear

        # Add scoop to PATH and then reload PATH
        Add-To-Path "$scoopPath\shims" "User"
        Update-Path
        Get-Command 'scoop' -ErrorAction 'Stop'
    }
}

<#
.SYNOPSIS
Install a package using scoop.

.DESCRIPTION
Uses scoop to install a package. By default, it will attempt to install with normal-user privileges (CURRENTLY BROKEN),
but optionally you may force installation with admin privileges.
You can also specify whether the package should be installed globally (requires admin privileges).

.PARAMETER Pkg
Name of the package that should be installed. Can include version (e.g. 'python@3.12.15').

.PARAMETER RunAsAdmin
Force installation with admin privileges (that is, running scoop with the privileges of the ResearchCloud install script).

.PARAMETER Global
Whether to install the package globally, instead of for the current user only. Implies -RunAsAdmin.

.INPUTS
None.

.OUTPUTS
None.
#>
Function Install-Scoop-Package() {
    param (
        [String] $Pkg,
        [Switch] $RunAsAdmin,
        [Switch] $Global
    )
    Write-SRC-Log ("Installing {0} via scoop" -f $Pkg)
    $scoopInstallLog = "$env:USERPROFILE\scoop_installer.log"

    $cmdArgs = @('install', $Pkg)

    if ($Global) {
        $cmdArgs += '--global'
    }

    if ($RunAsAdmin -or $Global) {
        & scoop @cmdArgs *> $scoopInstallLog
    } else {
        Invoke-Restricted-PS-Script "scoop install $cmdArgs"
    }

    Write-File-To-Log $scoopInstallLog -Clear
    Update-Path
}

<#
.SYNOPSIS
Install a scoop bucket.

.DESCRIPTION
Install a scoop bucket (that is, an additional package repo). Will install git (via scoop) if it is not present.

.PARAMETER Bucket
Name of the bucket that must be installed.

.INPUTS
None.

.OUTPUTS
None.
#>
Function Install-Scoop-Bucket() {
    param (
        [String] $Bucket
    )

    if (!(Get-Command "git" -errorAction SilentlyContinue)) {
        Install-Scoop-Package "git" -RunAsAdmin
    }

    Write-SRC-Log ("Installing scoop bucket {0}" -f $Bucket)
    scoop bucket add $Bucket
}
