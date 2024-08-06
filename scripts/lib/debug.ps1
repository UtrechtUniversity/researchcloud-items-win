$result = Get-Command 'Get-ExecutionPolicy'
Write-Output "Get-Command $result"

$result = cat "C:\Windows\system32\WindowsPowerShell\v1.0\Modules\Microsoft.PowerShell.Security\Microsoft.PowerShell.Security.psd1"
Write-Output "cat $result"

$result = Import-Module PowerShellGet
Write-Output "Import-Module $result"

$result = Get-InstalledModule
Write-Output "Get-Installed Modules $result"

$result = Get-Module -List
Write-Output "Get-Installed Modules 2 $result"

$result = Import-Module Microsoft.PowerShell.Security
Write-Output "Import-Module $result"

$result = Get-Module 'Microsoft.PowerShell.Security'
Write-Output "Get-Module $result"

$result = Get-Command 'Get-ExecutionPolicy'
Write-Output "Get-Command $result"