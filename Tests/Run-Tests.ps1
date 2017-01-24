Import-Module Pester

Invoke-Pester "$PSScriptRoot\*.Tests.ps1" -Tag 'Unit' -Verbose

