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
        [String]$LogText,
        [String]$LogFile = $LOGFILE
    )
    '{0:u}: {1}' -f (Get-Date), $LogText | Out-File $LogFile -Append
}

Function Add-To-Path {
    param (
        [String] $NewSegment,
        [String] $Target = 'Machine'
    )
    Write-SRC-Log "Adding $NewSegment to PATH for $Target"
    [Environment]::SetEnvironmentVariable(
        "Path",
        [Environment]::GetEnvironmentVariable("Path", $Target) + ";$NewSegment",
        $Target)
}

Function Convert-Newlines-LF([String] $File) {
    # Convert CRLF to LF
    # Add a trailing LF to the file
    # https://stackoverflow.com/a/48919146
    ((Get-Content $File) -join "`n") + "`n" | Set-Content -NoNewline $File
}

Function Install-SDelete([String] $InstallPath) {
    Write-SRC-Log "Installing SDelete"
    Invoke-WebRequest 'https://download.sysinternals.com/files/SDelete.zip' -OutFile SDelete.zip
    Expand-Archive SDelete.zip -DestinationPath $InstallPath
    rm SDelete.zip
}

Function SecureDelete {
    param (
        [String] $Path,
        [String] $InstallPath = "$env:USERPROFILE\sdelete"
    )

    if (Get-Command "sdelete.exe" -errorAction SilentlyContinue){
        $useDownloaded = $false
    } elseif (Test-Path "$InstallPath\sdelete.exe" -PathType Leaf) {
        $useDownloaded = $true
    } else {
        Install-SDelete $InstallPath
        $useDownloaded = $true
    }

    Write-SRC-Log "Using SDelete to delete $Path"

    if ( $useDownloaded ) {
        Push-Location -EA Stop $InstallPath
        .\sdelete.exe -nobanner -accepteula -q -p 2 -f $Path *>> $LOGFILE
        Pop-Location
    } else {
        sdelete.exe -nobanner -accepteula -q -p 2 -f $Path *>> $LOGFILE
    }
}
