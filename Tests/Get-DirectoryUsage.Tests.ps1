#region Resources
# Parameter Validation WorkAround in Pester
# https://groups.google.com/forum/#!topic/pester/CsKiMLld2Mg

#endregion

# If the module is already in memory, remove it
Get-Module FSTools -All | Remove-Module -Force

# Import the module from the local path, not from the users Documents folder
Import-Module "$PSScriptRoot\..\FSTools" -Force -Verbose

Describe 'Get-DirectoryUsage Tests' -Tags 'Unit' {

  InModuleScope FSTools {

    #region Arrange
      $TestFolder = New-Item -ItemType Directory "$($TestDrive)\$('TestFolder')"
      New-Item -ItemType File "$TestFolder\TestFile1.txt"

      $EmptyFolder = New-Item -ItemType Directory "$($TestDrive)\$('Emptyfolder')"

      $ExcludeFolder = New-Item -ItemType Directory "$TestFolder\ExcludeFolder"
      New-Item -ItemType File "$ExcludeFolder\TestFile3.txt"
      $testFile4 = New-Item -ItemType File "$ExcludeFolder\TestFile4.txt"
      Set-Content -Path $testFile4 -Value 'Test content'

      $properties = ('RootDirectory', 'Summary', 'Files', 'FilesCount', 'TotalUsage')
    #endregion

    Context 'Unit tests for values passed via PARAMETER' {

      Mock -Verifiable Write-Warning -ModuleName FSTools

      <#
				We should expect Get-DirectoryUsage to write a Warning message
				if the directory does not exist.
			#>
      It 'Should not process a non-existing directory' {
        Get-DirectoryUsage -Directory 'NonExistingDirectory'
        Assert-MockCalled Write-Warning -Exactly 1
      }

      It 'Should process an empty directory and the total number of files returned is zero' {
        $results = Get-DirectoryUsage -Directory $EmptyFolder
        $results.FilesCount | Should Be 0
      }

      It 'Should process an existing directory' {
        $results = Get-DirectoryUsage -Directory $TestFolder
        $results | Should Not BeNullOrEmpty
        $results.FilesCount | Should Be 3
      }

      It 'Should not process an excluded directory' {
        $results = Get-DirectoryUsage -Directory $TestFolder -Exclude 'ExcludeFolder'
        $results.FilesCount | Should Be 1
        $results.RootDirectory.foreach({ $_ -in @("$ExcludeFolder") | Should Be $false})
      }

    } #end Context 'Unit tests for values passed via PARAMETER'

    Context 'Unit tests for values passed via PIPELINE' {

      Mock -Verifiable Write-Warning -ModuleName FSTools

      It 'Should not process a non-existing directory' {
        'NonExistingDirectory' | Get-DirectoryUsage
        Assert-MockCalled Write-Warning -Exactly 1
      }

      It 'Should process an empty directory and the total number of files returned is zero' {
        $results = $EmptyFolder | Get-DirectoryUsage
        $results.FilesCount | Should Be 0
      }

      It 'Should process an existing directory' {
        $results = $TestFolder | Get-DirectoryUsage
        $results | Should Not BeNullOrEmpty
        $results.FilesCount | Should Be 3
      }

    } #end Context 'Unit tests for values passed via PIPELINE'

    $SourceValues = ('PIPELINE', 'PARAMETER')

    foreach ($Value in $SourceValues)
    {
      Context "Multiple Values passed via $Value should have the correct properties" {

        Mock -Verifiable Write-Warning -ModuleName FSTools

        if ($Value -eq 'PIPELINE')
        {
          $results = $TestFolder, 'NonExistingFolder', $EmptyFolder | Get-DirectoryUsage
          It 'Should not process a non-existing directory' {
            Assert-MockCalled Write-Warning -Exactly 1
          }

        }
        else
        {
          $results = Get-DirectoryUsage -Directory $TestFolder, 'NonExistingFolder', $EmptyFolder, 'MissingFolder'
          It 'Should not process a non-existing directory' {
            Assert-MockCalled Write-Warning -Exactly 2
          }
        }

        foreach ($property in $properties)
        {
          foreach ($result in $results)
          {
            It "should have a property of $property" {
              # All objects in PowerShell have a base type called PSObject
              [bool]($result.PSObject.Properties.Name -match $property) |
                Should Be $true
            }

          } #end foreach ($result in $results)

        } #end foreach ($property in $properties)

      } #end Context "Multiple Values passed via $Value should have the correct properties"

    } #end foreach($Value in $SourceValues)

  }

}
