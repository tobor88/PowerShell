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

        $person = Read-Host "Who is the person you want to view the conversation history of? Example: sip:rosborne@osbornepro.com"

        $savePath = "$env:USERPROFILE\Desktop"

        $StartDate = Read-Host "What should the start date of your search be? Example: 5/1/2019"

        $EndDate = Read-Host "What should the end date of your search be? Example: 5/10/2019"

        Write-Host "Reports will be saved to your desktop..."


    } # End BEGIN


    PROCESS {


        try {
         
            Export-CsArchivingData -Identity $ArchiveDatabase -StartDate $StartDate -EndDate $EndDate -OutputFolder $savePath -UserUri $person -Verbose 

            } # End Try

        catch {

            Write-Warning "An error occured. Make sure you entered the sip address correctly."

        } # End Catch


        $TheList = Get-ChildItem -Path "$savePath\$CreatedArchiveName" -Recurse | Where-Object -Property Name -like "*.eml" | Select-Object -Property Name,DirectoryName 

        $TheList.Name

        Write-Host "Above is a list of EML files. These contain conversation histories for the user you selected. `n$person" -ForegroundColor Yellow

        $otherParty = Read-Host "Enter the email address of the person $person had a conversation with. Example: dixie.normus@osbornepro.com"
        
        foreach ($convo in $TheList) {

            $convoDir = $convo.DirectoryName

            $convoFileName = $convo.Name

            $convoFullPathName = "$convoDir\$convoFileName"

            $containsWord = Get-Content -Path $convoFullPathName | ForEach-Object {$_ -contains "To: $otherParty"}

            If($containsWord -eq "True") {

                [array]$FileList += $convoFullPathName    

                Clear-Variable containsWord

            } # End If

            else {

                Clear-Variable containsWord

            } # End Else

        } # End Foreach


    } # End PROCESS

    END {


        foreach ($cFile in $FileList) {

            $totalLines = (Get-Content $cFile).Length

            [int]$baseLines = $totalLines - 14

            $baseEncoded = ((Get-Content -Path $cFile | Select-Object -Last $baseLines).TrimEnd("--MIME_Boundary-- ")) | Where-Object {$_ -ne ""}
            
            foreach ($lineSpace in $baseEncoded) {
            
                $base64 += $lineSpace.TrimEnd() | Where-Object {$_ -ne ""}

            } # End ForEach
                
            $printBase = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($base64)) 

            $printBase

            Clear-Variable base64,n,printBase

        } # End ForEach


    } # End END

} # End Function

Get-LyncArchives -Verbose
