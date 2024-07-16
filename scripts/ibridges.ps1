$ErrorActionPreference = 'Stop'

$LOGFILE = "c:\logs\ibridges.log"
$GLOBAL_PIPX_HOME = "c:\pipx"
$GLOBAL_PIPX_BIN = "c:\pipx\bin"
$IBRIDGES_TEMPLATE_PLUGIN = "git+https://github.com/UtrechtUniversity/ibridges-servers-uu.git"

. $PSScriptRoot\lib\common.ps1
. $PSScriptRoot\lib\scoop.ps1

Function Install-Global-Pipx 
    New-Item -ItemType Directory -Force -Path "$GLOBAL_PIPX_HOME"
    New-Item -ItemType Directory -Force -Path "$GLOBAL_PIPX_BIN"
    Write-SRC-Log "Installing pipx"
    Install-Scoop-Package "pipx"
    [System.Environment]::SetEnvironmentVariable('PIPX_HOME', $GLOBAL_PIPX_HOME)
    [System.Environment]::SetEnvironmentVariable('PIPX_BIN_DIR', $GLOBAL_PIPX_BIN)
    Add-To-Path -NewSegment "$GLOBAL_PIPX_BIN" -Target 'Machine'
}

Function Main {
    Write-SRC-Log "Start iBridges installation"
    try, {
        Install-Scoop
        Install-Scoop-Package "git"
        Install-Scoop-Package "python"
        Install-Global-Pipx
        $pkgs = "ibridges", "ibridgesgui"
        foreach ($pkg in $pkgs) {
            Write-SRC-Log "Installing $pkg"
            pipx install $pkg *>> $LOGFILE
            $targetVenv = "$GLOBAL_PIPX_HOME\venvs\$pkg\Lib\site-packages"
            pip install --target "$targetVenv" "$IBRIDGES_TEMPLATE_PLUGIN"
        }
        foreach ($location in 'CommonDesktopDirectory', 'CommonPrograms') {
          $shortcutLocation = Join-Path ([Environment]::GetFolderPath($location)) -ChildPath 'iBridges.lnk'
          New-Shortcut -Location $shortcutLocation -Target "$GLOBAL_PIPX_BIN\ibridges-gui.exe"
        }
    }
    catch {
        Write-SRC-Log "$_"
        Throw $_
    }
    Write-SRC-Log "iBridges installation completed succesfully"
}

Main
