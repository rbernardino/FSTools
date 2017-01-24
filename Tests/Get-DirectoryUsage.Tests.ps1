#region Resources
# Parameter Validation WorkAround in Pester
# https://groups.google.com/forum/#!topic/pester/CsKiMLld2Mg

#endregion

# If the module is already in memory, remove it
Get-Module FSTools | Remove-Module -Force

# Import the module from the local path, not from the users Documents folder
Import-Module .\FSTools.psm1 -Force

Describe 'Get-DirectoryUsage Tests' -Tags 'Unit' {
    
    InModuleScope FSTools {
        #region Setup

        $TestFolder = New-Item -ItemType Directory "$($TestDrive)$('TestFolder')"
        New-Item -ItemType File "$TestFolder\TestFile1.txt"
        New-Item -ItemType File "$TestFolder\TestFile2.txt"

        $EmptyFolder = New-Item -ItemType Directory "$($TestDrive)$('Emptyfolder')" 

        $properties = ('SearchDirectory', 'Location', 'Filename', 'Filesize')
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

            It 'Should process an empty directory but nothing is returned' {
                $Consumers = Get-DirectoryUsage -Directory $EmptyFolder
                $Consumers | Should BeNullOrEmpty 
            }

            It 'Should process an existing directory' {
                $Consumers = Get-DirectoryUsage -Directory $TestFolder
                $Consumers | Should Not BeNullOrEmpty 
            }

        } #end Context 'Unit tests for values passed via PARAMETER'

        Context 'Unit tests for values passed via PIPELINE' {
            
            Mock -Verifiable Write-Warning -ModuleName FSTools

            It 'Should not process a non-existing directory' {
                'NonExistingDirectory' | Get-DirectoryUsage
                Assert-MockCalled Write-Warning -Exactly 1
            }

            It 'Should process an empty directory but nothing is returned' {
                $Consumers = $EmptyFolder | Get-DirectoryUsage
                $Consumers | Should BeNullOrEmpty 
            }

            It 'Should process an existing directory' {
                $Consumers = $TestFolder | Get-DirectoryUsage
                $Consumers | Should Not BeNullOrEmpty
            }

        } #end Context 'Unit tests for values passed via PIPELINE'

        $SourceValues = ('PIPELINE', 'PARAMETER')

        foreach($Value in $SourceValues) 
        {
            Context "Multiple Values passed via $Value should have the correct properties" {

                Mock -Verifiable Write-Warning -ModuleName FSTools

                if ($Value -eq 'PIPELINE')
                {
                    $Consumers = $TestFolder, 'NonExistingFolder', $EmptyFolder | Get-DirectoryUsage
                    It 'Should not process a non-existing directory' {
                        Assert-MockCalled Write-Warning -Exactly 1
                    }
                                 
                } else {
                    $Consumers = Get-DirectoryUsage -Directory $TestFolder, 'NonExistingFolder', $EmptyFolder, 'MissingFolder'
                    It 'Should not process a non-existing directory' {
                        Assert-MockCalled Write-Warning -Exactly 2
                    }
                }
            
                foreach ($property in $properties) 
                {
                    foreach ($Consumer in $Consumers)
                    {
                        It "should have a property of $property" {
                            # All objects in PowerShell have a base type called PSObject
                            [bool]($Consumer.PSObject.Properties.Name -match $property) |
                                Should Be $true
                        }

                    } #end foreach ($Consumer in $Consumers)

                } #end foreach ($property in $properties) 

            } #end Context "Multiple Values passed via $Value should have the correct properties"

        } #end foreach($Value in $SourceValues) 
    }
     
}