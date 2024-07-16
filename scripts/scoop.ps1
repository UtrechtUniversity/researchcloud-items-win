$LOGFILE = "c:\logs\scoop.log"

. $PSScriptRoot\lib\scoop.ps1

Function Write-SRC-Log([String] $logText) {
    '{0:u}: {1}' -f (Get-Date), $logText | Out-File $LOGFILE -Append
}

Function Main {
    Write-SRC-Log "Start scoop installation"
    try {
        Install-Scoop
    }
    catch {
        Write-SRC-Log "$_"
        Throw $_
    }
    Write-SRC-Log "scoop installation completed succesfully"
}

Main
