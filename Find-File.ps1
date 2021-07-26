<#
.Synopsis
    Find-File is a cmdlet created to help a user find a file they only remeber part of the name of.
    It can also be used to find the location of a file where the name is remember but the location is not.
    This cmdlet was designed for users. As such no switches need to be defined. Running the cmdlet will prompt the user for input.

.DESCRIPTION
    This cmdlet searches the C: Drive for a rough file name and returns its location.
    If more than one file are found, more than one location will be returned.

.NOTES
    Author: Rob Osborne
    Alias: tobor
    Contact: rosborne@osbornepro.com
    https://osbornepro.com

.EXAMPLE
   Find-File

.EXAMPLE
   Find-File -Verbose

#>

Function Find-File {
    [CmdletBinding()]
        param(
            [Parameter(Mandatory=$True,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True,
                HelpMessage="The File's Name. `n Use * anywhere you are unsure of what comes next.`n * represents anything. `n Example: *USA*.txt `n If you see this message, you will need to press enter after being prompted to define a second file name. `n This will begin your search. `n Adding another file to search for will not work.")] # End Parameter
            [string[]]$FileName) # End param

    BEGIN {

        Write-Verbose "Begining Search. Please Wait..."

        $PathResults = Get-ChildItem -Path 'C:\' -Filter "$FileName" -Recurse -ErrorAction SilentlyContinue -Force

    } # End BEGIN

    PROCESS {

        if ($PathResults) {

            foreach ($Result in $PathResults) {

                $Properties = @{
                    File = $Result
                    Directory = $Result.DirectoryName
                    FullPath = $Result.FullName
                    LastAccessed = $Result.LastAccessTime
                    LastEdited = $Result.LastWriteTime
                    Created = $Result.CreationTime
                } # End Properties

                $obj = New-Object -TypeName PSCustomObject -Property $Properties

                Write-Output $obj

            } # End ForEach

        } # End if

        else {

            Write-Warning "No file found by that name on the C: Drive. `n If you feel you received this warning in error, `n 1.) Ensure you added a file extension `n 2.) Try to be less specific by using *. `n 3.) Only add one file name to search for"

        } # End Else

    } # End PROCESS

    END {

        Write-Verbose "Search Completed"

    } # End END

} # End Function

Find-File -Verbose

Pause
