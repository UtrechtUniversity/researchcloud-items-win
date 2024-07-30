$LOGFILE = "c:\logs\sas.log"
$SSH_KEY_LOCATION = "$env:USERPROFILE\.ssh\id_rsa"
$MOUNT_DRIVE = "S:" # Target drive to mount the robotserver on

. $PSScriptRoot\lib\common.ps1
. $PSScriptRoot\lib\scoop.ps1

Function Main {
    Write-SRC-Log "Start SAS"
    try {
        Initialize-SRC-Param 'sshkey', 'host', 'port', 'user', 'path' -Prefix 'sas_mount_'

        Write-SRC-Log "Saving key to $SSH_KEY_LOCATION"
        New-Item -ItemType Directory -Force -Path (Split-Path -parent $SSH_KEY_LOCATION)
        $sas_mount_sshkey | Out-File $SSH_KEY_LOCATION -encoding ascii
        Convert-Newlines-LF $SSH_KEY_LOCATION

        Install-Scoop
        Install-Scoop-Bucket "nonportable"
        Install-Scoop-Package "nonportable/winfsp-np"
        Install-Scoop-Package "nonportable/sshfs-np"

        $mountPath = $sas_mount_path -replace '/','\'
        Mount-SSHFS -Server $sas_mount_host -User $sas_mount_user -Port $sas_mount_port -Path $mountPath -Drive $MOUNT_DRIVE
    }
    catch {
        $CAUGHT = $true
        Write-SRC-Log $_
        Throw $_
    }
    finally {
        $ErrorActionPreference = 'Continue'

        Write-SRC-Log "Trying to unmount robot server"
        net use /delete $MOUNT_DRIVE

        SecureDelete -Path $SSH_KEY_LOCATION
        Write-SRC-Log "Removing key from $SSH_KEY_LOCATION"
        if ($CAUGHT) {
            Exit 1
        }
    }
    Write-SRC-Log "SAS component complete"
}

Write-Output "Logging to $LOGFILE"
Main

