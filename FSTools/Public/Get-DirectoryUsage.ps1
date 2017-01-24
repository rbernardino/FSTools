function Get-DirectoryUsage
{
<#
.SYNOPSIS
 Retrieves top disk space consumers under a given directory. 

.DESCRIPTION
 This function includes subdirectories when searching for large files.
 It does not include hidden files. It outputs an object of type 
 FSTools.DirectoryUsage.

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
  '\temp','C:\users\Downloads' | Get-DirectoryUsage | Format-Table -Groupby SearchDirectory -Wrap -Autosize

 .EXAMPLE
  '\temp','C:\users' | Get-DirectoryUsage  | Select-Object SearchDirectory,Filename,Location,@{ n='Filesize(MB)';e={"{0:N2}" -f ($_.Filesize / 1MB)} } | Format-Table -Groupby SearchDirectory -Wrap -Autosize
 
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
        [string[]]$Directory
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
               $consumers = Get-ChildItem $ADirectory -Recurse -File | 
                    Sort-Object length -Descending | 
                    Select-Object DirectoryName, Name, Length -First 10

               foreach($consumer in $consumers) 
               {
                   $props = @{
                        'SearchDirectory' = $ADirectory;
                        'Location'        = $consumer.DirectoryName;
                        'Filename'        = $consumer.Name;
                        'Filesize'        = $consumer.Length
                   }
                   
                   $obj = New-Object -TypeName PSObject -Property $props
                   $obj.PSObject.TypeNames.Insert(0,'FSTools.DirectoryUsage')
                   Write-Output $obj 
               }
            } else {
                Write-Warning "[$Prgname] $ADirectory does not exist"
                continue
            }

        } #end foreach
    }

    END
    {
        Write-Verbose "[$Prgname] Ending"  
    }
}