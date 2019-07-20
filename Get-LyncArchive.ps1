<#
.Synopsis
    Get-LyncArchives is used to get conversation history for a user and decode the base64 encoded conversation if wanted.
    This cmdlet does not accept any switches and will prompt the runner for input.
    User will be prompted for a user to look up, a user they had a conversation with, a start and end date.
    Lync Archive folder will be saved to the users desktop.
    Rather than prompting for a server name you will need to enter server information into the scripts defined fields

.DESCRIPTION
    This cmdlet is used to get conversation history for a user and decode the base64 encoded conversation.
    This should save the time of looking through each file and than decoding conversations that might not be what is looked for.
    Has been tested with Lync 2013 and Lync 2010

.AUTHOR
    Written by Rob Osborne - rosborne@osbornepro.com 
    Alias: tobor

.EXAMPLE
   Get-LyncArchives 

.EXAMPLE
   Get-LyncArchives -Verbose

#>

Function Get-LyncArchives {
    [CmdletBinding()]
        param()

    BEGIN {
        
        $ArchiveDatabase = "ArchivingDatabase:lyncArchiveServer.osbornepro.com"            ##########@@@##  DEFINE ME ################
     
        $CreatedArchiveName = "lyncArchiveServer.osbornepro.com_SqlDatabaseInstanceName"   ##########@@@##  DEFINE ME ################

        $Person = Read-Host "Who is the person you want to view the conversation history of? Example: sip:rosborne@osbornepro.com"

        $SavePath = "$env:USERPROFILE\Desktop"

        $StartDate = Read-Host "What should the start date of your search be? Example: 5/1/2019"

        $EndDate = Read-Host "What should the end date of your search be? Example: 5/10/2019"

        Write-Host "Reports will be saved to your desktop..."


    } # End BEGIN


    PROCESS {


        Try {
         
            Export-CsArchivingData -Identity $ArchiveDatabase -StartDate $StartDate -EndDate $EndDate -OutputFolder $SavePath -UserUri $Person -Verbose 

            } # End Try

        Catch {

            Write-Warning "An error occured. Make sure you entered the sip address correctly."

        } # End Catch


        $TheList = Get-ChildItem -Path "$SavePath\$CreatedArchiveName" -Recurse | Where-Object -Property Name -like "*.eml" | Select-Object -Property Name,DirectoryName 

        $TheList.Name

        Write-Host "Above is a list of EML files. These contain conversation histories for the user you selected. `n$person" -ForegroundColor Yellow

        $OtherParty = Read-Host "Enter the email address of the person $person had a conversation with. Example: dixie.normus@osbornepro.com"
        
        foreach ($Convo in $TheList) {

            $ConvoDir = $Convo.DirectoryName

            $ConvoFileName = $Convo.Name

            $ConvoFullPathName = "$ConvoDir\$ConvoFileName"

            $ContainsWord = Get-Content -Path $ConvoFullPathName | ForEach-Object {$_ -contains "To: $OtherParty"}

            If($ContainsWord -eq "True") {

                [array]$FileList += $ConvoFullPathName    

                Clear-Variable ContainsWord

            } # End If

            else {

                Clear-Variable ContainsWord

            } # End Else

        } # End Foreach

    } # End PROCESS

    END {

        foreach ($cFile in $FileList) {

            $TotalLines = (Get-Content $cFile).Length

            [int]$BaseLines = $TotalLines - 14

            $BaseEncoded = ((Get-Content -Path $cFile | Select-Object -Last $BaseLines).TrimEnd("--MIME_Boundary-- ")) | Where-Object {$_ -ne ""}
            
            foreach ($LineSpace in $BaseEncoded) {
            
                $base64 += $LineSpace.TrimEnd() | Where-Object {$_ -ne ""}

            } # End ForEach
                
            $PrintBase = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($base64)) 

            $PrintBase

            Clear-Variable base64,n,PrintBase

        } # End ForEach

    } # End END

} # End Function

Get-LyncArchives -Verbose
