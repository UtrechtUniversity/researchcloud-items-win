Import-Module "$PSScriptRoot\common.ps1"

Function Install-Scoop {
    param (
        [String]$LogFile = $LOGFILE
    )
    try {
        if (Get-Command "scoop" -errorAction SilentlyContinue) {
            Write-SRC-Log "Scoop already installed"
        }
        Else {
            Write-SRC-Log "Installing scoop"
            Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
            Invoke-RestMethod -Uri https://get.scoop.sh -Outfile 'install_scoop.ps1'
            .\install_scoop.ps1 2> $LogFile
        }
    }
    finally {
        Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope CurrentUser # Reset the execution policy
    }
}

Function Install-Scoop-Package() {
    param (
        [String] $Pkg,
        [String]$LogFile = $LOGFILE
    )
    Write-SRC-Log ("Installing {0} via scoop" -f $Pkg)
    scoop install $Pkg *>> $LogFile
}
