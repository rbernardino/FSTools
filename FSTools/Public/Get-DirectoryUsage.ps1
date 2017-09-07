function Get-DirectoryUsage
{
  <#
.SYNOPSIS
 Retrieves top disk space consumers under a given directory.

.DESCRIPTION
 This function includes subdirectories when searching for files. It does not include hidden files.
 It outputs an object of type FSTools.DirectoryUsage which contains properties like the summary of
 the subfolders' sizes with reference to the path and the list of all the files inside and within
 the subfolders of the given path.

.EXAMPLE
 Get-DirectoryUsage -Directory 'C:\users\Downloads'

.EXAMPLE
 Get-DirectoryUsage -Directory 'C:\'

.EXAMPLE
 '\temp','C:\users' | Get-DirectoryUsage

 DESCRIPTION
 -----------
 This example accepts values from the pipeline.

 .EXAMPLE
  '\temp','C:\users\Downloads' | Get-DirectoryUsage | Format-Table -Groupby RootDirectory -Wrap -Autosize

 .EXAMPLE
  '\temp','C:\users' | Get-DirectoryUsage  | Select-Object RootDirectory,FilesCount,@{ n='TotalUsage(MB)';e={"{0:N2}" -f ($_.TotalUsage / 1MB)} } | Format-Table -Groupby RootDirectory -Wrap -Autosize

 DESCRIPTION
 -----------
 The two previous examples demonstrate a use case for utilizing the output of this function.
 It gives the user the flexibility to format the output depending on his needs.
#>
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $True,
      ValueFromPipeline = $True,
      ValueFromPipelineByPropertyname = $True)]
    [string[]]$Directory,

    [int]$First = 10,

    [string[]]$Exclude
  )

  BEGIN
  {
    $Prgname = $($MyInvocation.MyCommand)
    Write-Verbose "[$Prgname] Starting"
  }

  PROCESS
  {
    foreach ($ADirectory in $Directory)
    {
      Write-Verbose "[$Prgname] Searching directory $ADirectory..."
      if ( (Test-Path $ADirectory -PathType Container) )
      {
        $rootFolderFiles = Get-ChildItem $ADirectory | Where-Object { -not $_.PSIsContainer }

        $foldersToSearch = Get-ChildItem $ADirectory | Where-Object { $_.PSIsContainer } |
          Where-Object {-not ($_ -in $Exclude)}

        # Get the size of each subdirectory
        $stats = $foldersToSearch | ForEach-Object {
          $files = Get-ChildItem $_.FullName -Recurse | Where-Object { -not $_.PSIsContainer }
          $filesStats = $files | Measure-Object -Property Length -Sum
          [pscustomobject]@{
            'Directory'  = $_
            'Size'       = $filesStats.Sum
            'TotalFiles' = $filesStats.Count
            'Files'      = $files
          }
        }

        $rootFolderFileStats = $rootFolderFiles | Measure-Object -Property Length -sum
        $subfolderFilesSize = $stats | Measure-Object -Property Size -sum
        $subfolderFilesTotal = $stats | Measure-Object -Property TotalFiles -sum

        $props = @{
          'RootDirectory' = $ADirectory
          'Summary'       = $stats | Select-Object Directory, Size
          'Files'         = $rootFolderFiles + $stats.Files
          'FilesCount'    = $rootFolderFileStats.count + $subfolderFilesTotal.Sum
          'TotalUsage'    = $rootFolderFileStats.sum + $subfolderFilesSize.sum
        }
        $obj = New-Object -TypeName PSObject -Property $props
        $obj.PSObject.TypeNames.Insert(0, 'FSTools.DirectoryUsage')
        Write-Output $obj
      }
      else
      {
        Write-Warning "[$Prgname] $ADirectory does not exist"
        continue
      }
    }
  } #end foreach

  END
  {
    Write-Verbose "[$Prgname] Ending"
  }
}
