Function Send-SendGridEmail {
<#
.SYNOPSIS
This cmdlet is used to send an email using the SendGrid API for use in PowerShell scripting situations


.DESCRIPTION
Send an email using PowerShell with the SendGrid API. If you have more than file to attach you will need to send a second email.
If you have more than one TO email address you will need to send a second email.


.PARAMETER ToAddress
Enter the TO address the email will be delivered

.PARAMETER ToName
Enter the TO name where the email will be delivered

.PARAMETER FromAddress
Enter the FROM address the email will be set from 

.PARAMETER FromName
Enter the FROM name the email will be sent from

.PARAMETER Subject
Subjet value for the email

.PARAMETER Body
Contents of the email message using Text formatting

.PARAMETER HTMLBody
Contents of the email message written in HTML format

.PARAMETER Attachment
Define a text or html based file to attach to the email

.PARAMETER APIKey
API token used to authenticate to the SendGrid API


.EXAMPLE
Send-SendGridEmail -To "recipient1@domain.com","recipient2@domain.com" -ToName "Recipient1 Name","Recipient 2 Name" -FromAddress "advisor360@vinebrookmsp.com" -FromName "Test Email from Advisor360" -Subject "Test Email" -Body "Hey this is a test email thank you!" -APIKey $APIKey
# This example sends an email to recipient1@domain.com|Recipient 1 Name and recipient2@domain.com|Recipient 2 Name from advisor360@vinebrookmsp.com|Test Email from Advisor360 using a Text formatted email body

.EXAMPLE
Send-SendGridEmail -To "recipient1@domain.com","recipient2@domain.com" -ToName "Recipient1 Name","Recipient 2 Name" -FromAddress "advisor360@vinebrookmsp.com" -FromName "Test Email from Advisor360" -Subject "Test Email" -HTMLBody "<br>Hey,<br> <br>This is a test email. <br><br>Thank you!" -Attachment C:\Temp\File.txt -APIKey $APIKey
# This example sends an email to recipient1@domain.com|Recipient 1 Name and recipient2@domain.com|Recipient 2 Name from advisor360@vinebrookmsp.com|Test Email from Advisor360 using an HTML formatted email body

.EXAMPLE
Send-SendGridEmail -To "recipient1@domain.com","recipient2@domain.com" -ToName "Recipient1 Name","Recipient 2 Name" -FromAddress "advisor360@vinebrookmsp.com" -FromName "Test Email from Advisor360" -Subject "Test Email" -Body "Hey this is a test email thank you!" -Attachment "C:\Temp\File1.txt","C:\Temp\File2.txt" -APIKey $APIKey
# This example sends an email to recipient1@domain.com|Recipient 1 Name and recipient2@domain.com|Recipient 2 Name from advisor360@vinebrookmsp.com|Test Email from Advisor360 using a Text formatted email body and incldues the 2 file attachments

.EXAMPLE
Send-SendGridEmail -To "recipient1@domain.com","recipient2@domain.com" -ToName "Recipient1 Name","Recipient 2 Name" -FromAddress "advisor360@vinebrookmsp.com" -FromName "Test Email from Advisor360" -Subject "Test Email" -HTMLBody "<br>Hey,<br> <br>This is a test email. <br><br>Thank you!" -APIKey $APIKey -Attachment "C:\Temp\File1.txt","C:\Temp\File2.txt"
# This example sends an email to recipient1@domain.com|Recipient 1 Name and recipient2@domain.com|Recipient 2 Name from advisor360@vinebrookmsp.com|Test Email from Advisor360 using an HTML formatted email body and incldues the 2 file attachments


.INPUTS 
None


.OUTPUTS
None


.LINK
https://osbornepro.com
https://encrypit.osbornepro.com
https://btpssecpack.osbornepro.com
https://writeups.osbornepro.com
https://github.com/OsbornePro
https://gitlab.com/tobor88
https://www.powershellgallery.com/profiles/tobor
https://www.hackthebox.eu/profile/52286
https://www.linkedin.com/in/roberthosborne/
https://www.credly.com/users/roberthosborne/badges


.NOTES
Author: Robert H. Osborne
Alias: tobor
Contact: rosborne@osbornepro.com
#>
param (
    [CmdletBinding(DefaultParameterSetName="Text")]
        [Parameter(
            Position = 0,
            Mandatory=$True,
            ValueFromPipeline=$False,
            HelpMessage="Enter the TO address the email will be delivered `nEXAMPLE: jsmith@domain.com ")]  # End Parameter
        [Alias("To")]
        [ValidateNotNullOrEmpty()]
        [String[]]$ToAddress,
    
        [Parameter(
            Position = 1,
            Mandatory=$False,
            ValueFromPipeline=$False,
            HelpMessage="Enter the TO name where the email will be delivered `nEXAMPLE: John Smith ")]  # End Parameter
        [String[]]$ToName,
    
        [Parameter(
            Position = 2,
            Mandatory=$True,
            ValueFromPipeline=$False,
            HelpMessage="REQUIRES A VERIFIED SENDER: `nEnter the FROM address the email will be set from `nEXAMPLE: general@vinebrooktech.com ")]  # End Parameter
        [Alias("From")]
        [ValidateScript($_ -like "*@*")]
        [String]$FromAddress,
    
        [Parameter(
            Position = 3,
            Mandatory=$False,
            ValueFromPipeline=$False,
            HelpMessage="Enter the FROM name the email will be sent from `nEXAMPLE: Vinebrook Technology ")]  # End Parameter
        [String]$FromName,
    
        [Parameter(
            Position = 4,
            Mandatory=$True,
            ValueFromPipeline=$False,
            HelpMessage="Enter a Subject for your email message `nEXAMPLE: Meeting Thursday ")]  # End Parameter
        [ValidateNotNullOrEmpty()]
        [String]$Subject,
    
        [Parameter(
            ParameterSetName="Text",
            Position = 5,
            Mandatory=$True,
            ValueFromPipeline=$False,
            HelpMessage="Enter a message to place in the body of your email `nEXAMPLE: Hi John, I look forward to our meeting ")]  # End Parameter
        [String]$Body,
    
        [Parameter(
            ParameterSetName="HTML",
            Position = 5,
            Mandatory=$True,
            ValueFromPipeline=$False,
            HelpMessage="Enter an HTML written message to place in the body of your email `nEXAMPLE: <br>Hi John,<br><br> I look forward to our meeting<br><br>    Thanks ")]  # End Parameter
        [String]$HTMLBody,
    
        [Parameter(
            Position = 6,
            Mandatory=$False,
            ValueFromPipeline=$False,
            HelpMessage="Enter the absolute path to a file you to attach to your email send. `nEXAMPLE: C:\temp\file.txt")]  # End Parameter
        [ValidateScript({Test-Path -Path $_})]
        [String[]]$Attachment,
    
        [Parameter(
            Position = 7,
            Mandatory=$True,
            ValueFromPipeline=$False,
            HelpMessage="Enter your SendGrid API key `nEXAMPLE: SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ")]  # End Parameter
        [ValidateScript({$_.Length -eq 69 -and $_ -like "SG.*"})]
        [String]$APIKey
    )  # End param

    If ($PSBoundParameters.ContainsKey("HTMLBody")) {
    
        $MailbodyType = 'text/HTML'
        $MailbodyValue = $HTMLBody
    
    } Else {
    
        $MailBodyType = 'text/plain'
        $MailBodyValue = $Body
    
    }  # End If Else

    $Count = 0
    $AllTo = @()
    ForEach ($T in $ToAddress) {

        $AllRecipients = @{}
        $AllRecipients."email" = $ToAddress[$Count]
        $AllRecipients."name"  = $ToName[$Count]
        
        $AllTo += $AllRecipients
        $Count++

    }  # End ForEach

    If ($PSBoundParameters.ContainsKey("Attachment")) {

        $AllAttachments = @()
        ForEach ($A in $Attachment) {
    
            $NewA = @{}
            $FileName = $A.Split("\")[-1]
            $Base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($A))
            $NewA."content"=$Base64
            $NewA."filename"=$FileName
            $NewA."type"="text/html"
            $NewA."disposition"="attachment"
            
            $AllAttachments += $NewA
    
        }  # End ForEach

    }  # End If

    $SendGridBody = @{
        "personalizations" = @(
            @{
                "to" = @(
                    $AllTo
                )
                "subject" = $Subject
            }
        )  # End personalizations
        "content" = @(
            @{
                "type"  = $MailBodyType
                "value" = $MailBodyValue
            }
        )  # End content
        "from" = @{
            "email" = $FromAddress
            "name"  = $FromName
        }  # End from
    
    }  # End $SendGridBody

    If ($AllAttachments) {

        $SendGridBody.attachments = @($AllAttachments)

    }  # End If

    $BodyJson = $SendGridBody | ConvertTo-Json -Depth 10
    $Header = @{
        "Authorization" = "Bearer $APIKey"
    }  # End $Header

    Invoke-RestMethod -Method POST -Uri https://api.sendgrid.com/v3/mail/send -Headers $Header -Body $BodyJson -ContentType "application/json"

}  # End Send-SendGridEmail
