Import-Module "$PSScriptRoot\common.ps1"

Function Install-Scoop {
    param (
        [String]$logFile = $LOGFILE
    )
    try {
        if (Get-Command "scoop" -errorAction SilentlyContinue) {
            Write-SRC-Log "Scoop already installed"
        }
        Else {
            Write-SRC-Log "Installing scoop"
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
            Invoke-RestMethod -Uri https://get.scoop.sh -Outfile 'install_scoop.ps1'
            .\install_scoop.ps1 2> $logFile
        }
    }
    finally {
        Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope CurrentUser # Reset the execution policy
    }
}

Function Install-Scoop-Package([String] $pkg) {
    Write-SRC-Log ("Installing {0} via scoop" -f $pkg)
    scoop install $pkg *>> $LOGFILE
}
