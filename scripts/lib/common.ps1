$LOGFILE = if ( $LOGFILE ) { $LOGFILE } else { 'C:\logs\common.log' }
$ICONDIR = "$PSScriptRoot\..\..\imgs"
$ICONDEST = "C:\src-misc\icons"

# Run a command with restricted privileges and wait for its execution to be completed
Function Invoke-Restricted() {
    param (
        [String] $MyCommand
    )

    Write-SRC-Log "Command to be run in restricted mode: $MyCommand"
    $result = Start-Process -PassThru -NoNewWindow -Wait runas.exe @"
/trustlevel:0x20000 "$MyCommand"
"@

    $stdout = $p.StandardOutput
    if ($stdout) {
        Write-SRC-Log "$MyCommand captured stdout: $($stdout.ReadToEnd())"
    }
    $stderr = $p.StandardError
    if ($stderr) {
        Write-SRC-Log "$MyCommand captured stderr: $($stderr.ReadToEnd())"
    }

    if ($result.ExitCode) {
        throw "Attempted to run '$MyCommand' with restricted privileges, but it exited with statuscode $($result.ExitCode)"
    }
}

# Run a PS script with restricted privileges and wait for its execution to be completed
Function Invoke-Restricted-PS-Script() {
    param (
        [String] $ScriptPath,
        [String] $LogPath = ''
    )

    $pwshPath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName # Get the path to the .exe running this script, to ensure we call the same version of powershell with Invoke-Restricted.
    $setModulePath = "`$env:PSModulePath='$env:PSModulePath'" # Ensure that pwsh in the 'runas' context loads the same modules as the shell executing this script
    $runCommand = "$pwshPath -ExecutionPolicy Bypass -c $setModulePath; & `"$ScriptPath`""
    if ( $LogPath ) {
         $runCommand = "$runCommand *>> `"$LogPath`""
    }
    Invoke-Restricted($runCommand)
}

Function Install-Icon([String]$Name) {
    . {
        New-Item -ItemType Directory -Force -Path $ICONDEST
        Copy-Item "$ICONDIR\$Name.ico" -Destination $ICONDEST
    } | Out-Null
    return "$ICONDEST\$Name.ico"
}

Function New-Shortcut() {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [String] $Location,
        [String] $Target,
        [String] $IconName = ''
    )
    if($PSCmdlet.ShouldProcess($Location)){
        $WScriptShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WScriptShell.CreateShortcut($Location)
        $Shortcut.TargetPath = $Target
        if ( $IconName ) {
            $Shortcut.IconLocation = Install-Icon($IconName)
        }
        $Shortcut.Save()
    }
}

Function Write-File-To-Log {
    param (
        [String]$LogPath,
        [String]$Prefix = "",
        [Switch]$Clear
    )

    if ($Prefix) {
        $linePrefix = $Prefix
    } else {
        $linePrefix = $LogPath
    }

    $result = Get-Content -LiteralPath $LogPath -EA 'Continue'

    if ($result) {
        ForEach ($line in $($result -split "`r`n"))
        {
            Write-SRC-Log "$($linePrefix): $line"
        }
        if ($Clear) {
            Clear-Content -Path $LogPath -Force
        }
    }
}

Function Write-SRC-Log {
    param (
        [String]$LogText,
        [String]$LogFile = $LOGFILE
    )
    Write-Output $LogText
    '{0:u}: {1}' -f (Get-Date), $LogText | Out-File $LogFile -Append
}

Function Add-To-Path {
    param (
        [String] $NewSegment,
        [String] $Target = 'Machine'
    )
    [Environment]::SetEnvironmentVariable(
        "Path",
        [Environment]::GetEnvironmentVariable("Path", $Target) + ";$NewSegment",
        $Target)
}

Function Update-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-SRC-Log "Set PATH to $env:Path"
}

Function Convert-Newlines-LF([String] $File) {
    # Convert CRLF to LF
    # Add a trailing LF to the file
    # https://stackoverflow.com/a/48919146
    ((Get-Content $File) -join "`n") + "`n" | Set-Content -NoNewline $File
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
        Write-SRC-Log "Installing SDelete"
        Invoke-WebRequest 'https://download.sysinternals.com/files/SDelete.zip' -OutFile SDelete.zip
        Expand-Archive SDelete.zip -DestinationPath $InstallPath
        rm SDelete.zip
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

# Mount a remote share to $Drive using SSHFS
# Assumes sshfs-ws and winfsp are already installed
Function Mount-SSHFS {
    param (
        [String]$Server,
        [String]$User,
        [String]$Port,
        [String]$Path,
        [String]$Drive
    )
    if (Get-Volume -FilePath "$Drive\") {
        throw 'Drive $Drive is already mounted, exiting.'
    }
    $serverUNC = "\\sshfs.kr\$User@$Server!$Port$Path"
    Write-SRC-Log "Connecting to $serverUNC"
    $cmdOutput = (net use $Drive "$serverUNC" 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0) {
        throw $cmdOutput
    }
}

Function Initialize-SRC-Param {
    param (
        [String[]] $ReqParams,
        [String] $Prefix = ""
    )
    foreach ($param in $ReqParams) {
        $varName = "$prefix$param"
        $val = [System.Environment]::GetEnvironmentVariable($varName)
        if (!$val) {
            Throw "ERROR: mandatory ResearchCloud parameter $varName not defined."
        }
        else {
            New-Variable -Name $varName -Value $val -Scope 1
        }
    }
}
