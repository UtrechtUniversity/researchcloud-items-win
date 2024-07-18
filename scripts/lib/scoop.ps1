 . $PSScriptRoot\common.ps1

Function Install-Scoop {
    try {
        if (Get-Command "scoop" -errorAction SilentlyContinue) {
            Write-SRC-Log "Scoop already installed"
        }
        Else {
            Write-SRC-Log "Installing scoop"
            Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
            $installerPath = "$env:USERPROFILE\install_scoop.ps1"
            Invoke-RestMethod -Uri https://get.scoop.sh -Outfile $installerPath
            RunRestricted "powershell.exe -c & $installerPath"
            # Add scoop to PATH and then reload PATH
            Add-To-Path "$env:USERPROFILE\scoop\shims" "User"
            ReloadPath
            Get-Command "scoop" -errorAction Stop
        }
    }
    finally {
        Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope CurrentUser # Reset the execution policy
    }
}

Function Install-Scoop-Package() {
    param (
        [String] $Pkg,
        [String]$LogFile = $LOGFILE
    )
    Write-SRC-Log ("Installing {0} via scoop" -f $Pkg)
    RunRestricted "cmd.exe /c scoop install $Pkg"
}
