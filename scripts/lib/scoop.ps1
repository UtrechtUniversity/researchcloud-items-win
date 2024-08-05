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
            $scoopPath = "$env:USERPROFILE\scoop"
            $scoopInstallLog = "$env:USERPROFILE\scoop.log"
            $installCmd = "powershell.exe & `"$installerPath`" *>> `"$scoopInstallLog`""

            Invoke-RestMethod -Uri https://get.scoop.sh -Outfile $installerPath
            Invoke-Restricted $installCmd
            $result = Get-Content -LiteralPath $scoopInstallLog
            ForEach ($line in $($result -split "`r`n"))
            {
                Write-SRC-Log "Scoop installer: $result"
            }

            # Add scoop to PATH and then reload PATH
            Add-To-Path "$scoopPath\shims" "User"
            ReloadPath
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
    Invoke-Restricted "cmd.exe /c scoop install $Pkg"
}

Function Install-Scoop-Bucket() {
    param (
        [String] $Bucket
    )
    Write-SRC-Log ("Installing scoop bucket {0}" -f $Bucket)
    scoop bucket add $Bucket
}
