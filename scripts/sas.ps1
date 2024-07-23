$LOGFILE = "c:\logs\sas.log"
$SSH_KEY_LOCATION = "$env:USERPROFILE\.ssh\id_rsa"
$MOUNT_DRIVE = "S:" # Target drive to mount the robotserver on

. $PSScriptRoot\lib\common.ps1
. $PSScriptRoot\lib\scoop.ps1

Function Main {
    Write-SRC-Log "Start SAS"
    try {
        $allParamsPresent = $true
        foreach ($param in 'sshkey', 'host', 'port', 'user', 'path') {
            $varName = "robotmount_$param"
            $val = [System.Environment]::GetEnvironmentVariable($varName)
            if (!$val) {
                Write-SRC-Log "ERROR: mandatory ResearchCloud parameter $varName not defined."
                $allParamsPresent = $false
            }
            else {
                New-Variable -Name $varName -Value $val
            }
        }

        if (!$allParamsPresent) {
            Exit 1
        }

        Write-SRC-Log "Saving key to $SSH_KEY_LOCATION"
        New-Item -ItemType Directory -Force -Path (Split-Path -parent $SSH_KEY_LOCATION)
        $robotmount_sshkey | Out-File $SSH_KEY_LOCATION -encoding ascii
        Convert-Newlines-LF $SSH_KEY_LOCATION

        Install-Scoop
        Install-Scoop-Bucket "nonportable"
        Install-Scoop-Package "nonportable/winfsp-np"
        Install-Scoop-Package "nonportable/sshfs-np"

        $mountPath = $robotmount_path -replace '/','\'
        Mount-SSHFS -Server $robotmount_host -User $robotmount_user -Port $robotmount_port -Path $mountPath -Drive $MOUNT_DRIVE
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

