$LOGFILE = if ( $LOGFILE ) { $LOGFILE } else { 'C:\logs\common.log' }
$ICONDIR = "$PSScriptRoot\..\..\imgs"
$ICONDEST = "C:\src-misc\icons"

<#
.SYNOPSIS
Set permissions for a directory.

.DESCRIPTION
Set permissions for a directory, and optionally its children.

.PARAMETER DirPath
Path to the directory.

.PARAMETER Group
Group for which the new permissions should be set (default: "everyone").

.PARAMETER Permission
The permission to be allowed or denied (default: "Read").

.PARAMETER Allow
Whether to allow or deny the specified permission for the group (default: "Allow").

.PARAMETER NoOverride
By default, this function will override any Acl rules the folder inherits from its parents. This switch disables that behavior.

.PARAMETER Recursive
Whether to make subfolders and subitems inherit the permission.

.INPUTS
None.

.OUTPUTS
None.
If runas.exe itself throws an error (because the requested command cannot be run with normal user privileges, say),
an error is thrown.
#>
function Set-Dir-Access() {
    param (
        [String] $DirPath,
        [String] $Group = 'everyone',
        [String] $Permission = 'Read',
        [String] $Allow = 'Allow',
        [Switch] $NoOverride,
        [Switch] $Recursive
    )
    $Acl = Get-ACL $DirPath
    if (!$NoOverride){
         $Acl.SetAccessRuleProtection($true, $false)
    }
    if ($Recursive) {
        $Inheritance = 3
    } else {
        $Inheritance = 0
    }
    $Propagation = 0
    $AccessRule= New-Object System.Security.AccessControl.FileSystemAccessRule($Group, $Permission, $Inheritance, $Propagation, $Allow)
    $Acl.AddAccessRule($AccessRule)
    Set-Acl $DirPath $Acl
}

<#
.SYNOPSIS
Run a command with normal user privileges.

.DESCRIPTION
Uses runas.exe to run an arbitrary command with normal user privileges.
Useful since ResearchCloud components are executed with admin privileges, and this may raise security issues in some cases.
Note that we cannot directly redirect output from the command to a powershell variable.
If you wish to capture the output of the command, redirect it to a file and use the Write-File-To-Log function:
for instance, you can pass "foo > $myLogFile 2>&1" to MyCommand.

.PARAMETER MyCommand
The command that should be invoked.

.INPUTS
None.

.OUTPUTS
None.
If runas.exe itself throws an error (because the requested command cannot be run with normal user privileges, say),
an error is thrown.
#>
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

<#
.SYNOPSIS
Run a PS script with normal user privileges.

.DESCRIPTION
Uses the Invoke-Restricted function to run a PS script with normal user privileges.
Output can optionally be logged to a file, as normal output capturing won't work due to the fact the script will be run using runas.exe.
You may use the Write-File-To-Log function to log the contents of the specified logfiles.
To ensure that the invoked script behaves in the expected way, the exact same PowerShell executable that calls this function will be used.
The module paths for the current session will also be used.

.PARAMETER ScriptPath
Path to the script that should be invoked, or a block of PS code to be run.

.PARAMETER LogPath
Optional path to a logfile to which output of the invoked script should be redirected.

.PARAMETER ExecPolicy
Optional ExecPolicy that should be used for running the script.

.INPUTS
None.

.OUTPUTS
None.
#>
Function Invoke-Restricted-PS-Script() {
    param (
        [String] $Script,
        [String] $LogPath = '',
        [String] $ExecPolicy = 'Bypass'
    )

    $pwshPath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName # Get the path to the .exe running this script, to ensure we call the same version of powershell with Invoke-Restricted.
    # Ensure that pwsh in the 'runas' context has the same Path and ModulePath as the shell executing this script
    $setModulePath = "`$env:PSModulePath='$env:PSModulePath'"
    $setPath = "`$env:PATH='$env:PATH'"

    $runCommand = "$pwshPath -ExecutionPolicy $ExecPolicy -c $setPath; $setModulePath; cd; & $Script"
    if ( $LogPath ) {
         $runCommand = "$runCommand *>> `"$LogPath`""
    }
    Invoke-Restricted $runCommand
}

<#
.SYNOPSIS
Copy an icon file from this repo to a shared location on the workspace.

.DESCRIPTION
Copy an icon file from this repo to a shared location on the workspace.

.PARAMETER Name
Filename of the icon. Expected to be under the $ICONDIR location in this repository.
Will be installed to the $ICONDEST location on the workspace.

.INPUTS
None.

.OUTPUTS
Returns the location of the installed icon on the workspace.
#>
Function Install-Icon([String]$Name) {
    . {
        New-Item -ItemType Directory -Force -Path $ICONDEST
        Copy-Item "$ICONDIR\$Name.ico" -Destination $ICONDEST
    } | Out-Null
    return "$ICONDEST\$Name.ico"
}

<#
.SYNOPSIS
Create a shortcut with an optional custom icon.

.DESCRIPTION
Create a shortcut with an optional custom icon.

.PARAMETER Location
Where the shortcut should be created.

.PARAMETER Target
Where the shortcut should link to.

.PARAMETER IconName
Name of the icon file to use for the shortcut. See the Install-Icon function.

.INPUTS
None.

.OUTPUTS
None.
#>
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

<#
.SYNOPSIS
Log the contents of a file, line by line.

.DESCRIPTION
Log the contents of a file to ResearchCloud and to a logfile on the workspace.

.PARAMETER LogPath
The path to the file the contents of which should be logged

.PARAMETER Prefix
Prefix to be added to each line of the file when logging. Defaults to the filename of the log.

.INPUTS
None.

.OUTPUTS
None.
#>
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

<#
.SYNOPSIS
Log text to ResearchCloud and to a logfile on the workspace.

.DESCRIPTION
Log text to ResearchCloud and to a logfile on the workspace.

.PARAMETER LogText
The String to be logged.

.PARAMETER LogFile
Where the log on the machine should be written to. Defaults to the value of the $LOGFILE global variable, which should be set by the component script.

.INPUTS
None.

.OUTPUTS
None.
#>
Function Write-SRC-Log {
    param (
        [String]$LogText,
        [String]$LogFile = $LOGFILE
    )
    Write-Output $LogText
    '{0:u}: {1}' -f (Get-Date), $LogText | Out-File $LogFile -Append
}

<#
.SYNOPSIS
Add a segment to the default path for Machine or User.

.DESCRIPTION
Add a segment to the default path for Machine or User.

.PARAMETER NewSegment
The location to add to the path.

.PARAMETER Target
The target scope of the path to change (e.g. 'Machine', 'User').

.INPUTS
None.

.OUTPUTS
None.
#>
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

<#
.SYNOPSIS
Resets the path for the current session to the default path for the machine and user.

.DESCRIPTION
Resets the path for the current session to the default path for the machine and user.

.INPUTS
None.

.OUTPUTS
None.
#>
Function Update-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-SRC-Log "Set PATH to $env:Path"
}

<#
.SYNOPSIS
Convert Unix-style line endings to Windows-style line endings in a file.

.DESCRIPTION
Convert Unix-style line endings to Windows-style line endings in a file.

.PARAMETER File
Path to the file to convert.

.INPUTS
None.

.OUTPUTS
None.
#>
Function Convert-Newlines-LF([String] $File) {
    # Convert CRLF to LF
    # Add a trailing LF to the file
    # https://stackoverflow.com/a/48919146
    ((Get-Content $File) -join "`n") + "`n" | Set-Content -NoNewline $File
}

<#
.SYNOPSIS
Securely delete a file.

.DESCRIPTION
Uses the SDelete program (installed if not present) to delete a file in a way that does not allow it to be easily recovered.

.PARAMETER Path
Path of the file to delete.

.PARAMETER InstallPath
Path where SDelete should be installed, if it is not yet present.

.INPUTS
None.

.OUTPUTS
None.
#>
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

<#
.SYNOPSIS
Mount a remote share using SSHFS.

.DESCRIPTION
Mount a remote share using SSHFS. Assumes sshfs-ws and winfsp are already installed.

.PARAMETER Server
IP or hostname of server to connect to.

.PARAMETER User
Username to use to connect to server.

.PARAMETER Path
Port to connect to on the server.

.PARAMETER Path
Path to the SSHFS share on the server.

.PARAMETER Drive
Drive name to mount to (e.g. "D:").

.INPUTS
None.

.OUTPUTS
None.
#>
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

<#
.SYNOPSIS
Initialize parameters set by ResearchCloud as local variables.

.DESCRIPTION
Detect mandatory environment variables that should be set by ResearchCloud, creates local variables for each, and throws
an error if one is not set.

.PARAMETER ReqParams
Array of Strings containing ResearchCloud parameter names.

.PARAMETER Prefix
Determines the name of the local variables that will be created. For instance, with Prefix 'foo' and parameter name 'bar', a variable 'foo_bar' will be created with the value of the 'bar' environment variable.

.INPUTS
None.

.OUTPUTS
None. The function initializes a set of local variables.
#>
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
