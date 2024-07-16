$LOGFILE = if ( $LOGFILE ) { $LOGFILE } else { 'C:\logs\common.log' }

Function New-Shortcut() {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [String] $Location,
        [String] $Target
    )
    if($PSCmdlet.ShouldProcess($Location)){
        $WScriptShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WScriptShell.CreateShortcut($Location)
        $Shortcut.TargetPath = $Target
        $Shortcut.Save()
    }
}

Function Write-SRC-Log {
    param (
        [String]$logText,
        [String]$logFile = $LOGFILE
    )
    '{0:u}: {1}' -f (Get-Date), $logText | Out-File $logFile -Append
}