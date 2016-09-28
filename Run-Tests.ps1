Import-Module Pester

Invoke-Pester ".\function-Get-DirectoryUsage.Tests.ps1" -Tag 'Unit' -Verbose