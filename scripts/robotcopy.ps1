$LOGFILE = "c:\logs\robotcopy.log"
$SSH_KEY_LOCATION = "$env:USERPROFILE\.robotcopy\id_rsa"
$PACKAGES = "$env:USERPROFILE\robotpkgs"

. $PSScriptRoot\lib\common.ps1

Function Main {
    Write-SRC-Log "Start Robot Copy"
    try {

        Initialize-SRC-Param 'sshkey', 'host', 'port', 'user', 'path' -Prefix 'robotcopy_'
        Write-SRC-Log "Saving key to $SSH_KEY_LOCATION"
        New-Item -ItemType Directory -Force -Path (Split-Path -parent $SSH_KEY_LOCATION)
        $robotcopy_sshkey | Out-File $SSH_KEY_LOCATION -encoding ascii
        Convert-Newlines-LF $SSH_KEY_LOCATION

        New-Item -ItemType Directory -Force -Path $PACKAGES
        $copyTarget = "$PACKAGES\$(Split-Path -Leaf $robotcopy_path)"

        Write-SRC-Log "Attempting to copy $robotcopy_path from $robotcopy_host on port $robotcopy_port as user $robotcopy_user to $copyTarget"
        $scpSource = "${robotcopy_user}@${robotcopy_host}:${robotcopy_path}"
        scp -o StrictHostKeyChecking=no -i $SSH_KEY_LOCATION -P "$robotcopy_port" $scpSource "$copyTarget" *>> $LOGFILE
    }
    catch {
        $CAUGHT = $true
        Write-SRC-Log $_
        Throw $_
    }
    finally {
        Write-SRC-Log "Removing key from $SSH_KEY_LOCATION"
        SecureDelete -Path $SSH_KEY_LOCATION
        if ($CAUGHT) {
            Exit 1
        }
    }
    Write-SRC-Log "Robot Copy complete"
}

Write-Output "Logging to $LOGFILE"
Main
