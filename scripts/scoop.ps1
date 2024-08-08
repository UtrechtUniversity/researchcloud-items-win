$LOGFILE = "c:\logs\scoop.log"

. $PSScriptRoot\lib\scoop.ps1

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


Write-Output "Logging to $LOGFILE"
Main
