 . $PSScriptRoot\common.ps1

Function Install-Scoop {
    if (Get-Command "scoop" -errorAction SilentlyContinue) {
        Write-SRC-Log "Scoop already installed"
    }
    Else {
        Write-SRC-Log "Installing scoop"

        $installerPath = "$env:USERPROFILE\install_scoop.ps1"
        #$installerPath = "$PSScriptRoot\debug.ps1"
        $scoopPath = "$env:USERPROFILE\scoop"
        $scoopInstallLog = "$env:USERPROFILE\scoop.log"
        $pwshPath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName # Get the path to the .exe running this script, to ensure we call the same version of powershell with Invoke-Restricted
        $installCmd = "$pwshPath -ExecutionPolicy Bypass -c & `"$installerPath`" *>> `"$scoopInstallLog`""

        #Invoke-RestMethod -Uri https://get.scoop.sh -Outfile $installerPath
        Invoke-Restricted $installCmd

        $result = Get-Content -LiteralPath $scoopInstallLog
        if ($result) {
            ForEach ($line in $($result -split "`r`n"))
            {
                Write-SRC-Log "Scoop installer: $line"
            }
        }

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
    scoop bucket add $Bucket
}
