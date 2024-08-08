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

        $result = Get-Content -LiteralPath $scoopInstallLog
        if ($result) {
            ForEach ($line in $($result -split "`r`n"))
            {
                Write-SRC-Log "Scoop installer: $line"
            }
        }

        Get-Command 'scoop' -ErrorAction 'Stop'

        # Add scoop to PATH and then reload PATH
        Add-To-Path "$scoopPath\shims" "User"
        ReloadPath
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
    Invoke-Restricted "cmd.exe /c scoop bucket add $Bucket"
}
