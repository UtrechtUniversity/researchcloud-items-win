if (Get-Command 'Get-ExecutionPolicy' -errorAction SilentlyContinue) {
    Write-Output 'Get-ExecutionPolicy exists'
} else {
    Write-Output 'Get-ExecutionPolicy does not exist'
}

$result = Get-Command 'Get-ExecutionPolicy'
Write-Output "Get-Command $result"

$result = Get-InstalledModule
Write-Output "Get-Installed Module $result"

$result = Get-Module 'Microsoft.PowerShell.Security'
Write-Output "Get-Module $result"

$result = cat "C:\Windows\system32\WindowsPowerShell\v1.0\Modules\Microsoft.PowerShell.Security\Microsoft.PowerShell.Security.psd1"
Write-Output $result
