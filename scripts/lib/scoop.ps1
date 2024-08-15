. $PSScriptRoot\common.ps1

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
