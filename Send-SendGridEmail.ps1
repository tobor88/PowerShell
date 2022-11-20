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
Send-SendGridEmail -ToAddress destination@domain.com -ToName "Destination Name" -FromAddress info@osbonrepro.com -FromName "OsbornePro Information" -Subject "Test Email" -Body "Hey, This is a test email. Thank you!" -APIKey $APIKey
# This example sends an email to destination@domain.com replacing the display name with Destination Name from info@osbornepro.com replacing the From name with "OsbornePro Information" using an text body email

.EXAMPLE 
Send-SendGridEmail -ToAddress destination@domain.com -ToName "Destination Name" -FromAddress info@osbonrepro.com -FromName "OsbornePro Information" -Subject "Test Email" -HTMLBody "<br>Hey,<br> <br>This is a test email. <br><br>Thank you!" -Attachment C:\Temp\File.txt -APIKey $APIKey
# This example sends an email to destination@domain.com replacing the display name with Destination Name from info@osbornepro.com replacing the From name with "OsbornePro Information" using an HTML body email. It attached the file C:\Temp\file.txt to the email


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
[CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            Mandatory=$True,
            ValueFromPipeline=$False,
            HelpMessage="Enter the TO address the email will be delivered `nEXAMPLE: jsmith@domain.com ")]  # End Parameter
        [Alias("To")]
        [String]$ToAddress,

        [Parameter(
            Position = 1,
            Mandatory=$False,
            ValueFromPipeline=$False,
            HelpMessage="Enter the TO name where the email will be delivered `nEXAMPLE: John Smith ")]  # End Parameter
        [String]$ToName,

        [Parameter(
            Position = 2,
            Mandatory=$True,
            ValueFromPipeline=$False,
            HelpMessage="REQUIRES A SENDGRID VERIFIED SENDER: `nEnter the FROM address the email will be set from `nEXAMPLE: info@osbornepro.com ")]  # End Parameter
        [Alias("From")]
        [ValidateScript({$_ -like "*@*.*"})]
        [String]$FromAddress,

        [Parameter(
            Position = 3,
            Mandatory=$False,
            ValueFromPipeline=$False,
            HelpMessage="Enter the FROM name the email will be sent from `nEXAMPLE: OsbornePro Information ")]  # End Parameter
        [String]$FromName,

        [Parameter(
            Position = 4,
            Mandatory=$True,
            ValueFromPipeline=$False,
            HelpMessage="Enter a Subject for your email message `nEXAMPLE: Meeting Thursday ")]  # End Parameter
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
            ParameterSetName="HTML",
            Position = 6,
            Mandatory=$False,
            ValueFromPipeline=$False,
            HelpMessage="Enter the absolute path to a file you to attach to your email send. `nEXAMPLE: C:\temp\file.txt")]  # End Parameter
        [ValidateScript({Test-Path -Path $_})]
        [String]$Attachment,

        [Parameter(
            Mandatory=$True,
            ValueFromPipeline=$False,
            HelpMessage="Enter your SendGrid API key `nEXAMPLE: SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ")]  # End Parameter
        [ValidateScript({$_.Length -eq 69 -and $_ -like "SG.*"})]
        [String]$APIKey
    )  # End param

    
    If ($PSBoundParameters.ContainsKey('HTMLBody')) {

        $MailbodyType = 'text/HTML'
        $MailbodyValue = $HTMLBody

    } Else {

        $MailBodyType = 'text/plain'
        $MailBodyValue = $Body

    }  # End If Else

    If ($Attachment.Length -gt 2) {

        $FileName = $Attachment.Split("\")[-1]
        $Base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($Attachment))
        $SendGridBody = @{
            "personalizations" = @(
                @{
                    "to"      = @(
                        @{
                            "email" = $ToAddress
                            "name"  = $ToName
                        }
                    )
                    "subject" = $Subject
                }
            )  # End personalizations
            "content"          = @(
                @{
                    "type"  = $MailBodyType
                    "value" = $MailBodyValue
                }
            )  # End content
            "from"             = @{
                "email" = $FromAddress
                "name"  = $FromName
            }  # End from
            "attachments" = @(
                @{
                    "content"=$Base64 
                    "filename"=$FileName
                    "type"=$MailbodyType
                    "disposition"="attachment"
                }
            )  # End attachments
        }  # End $SendGridBody

    } Else { 
    
        $SendGridBody = @{
            "personalizations" = @(
                @{
                    "to"      = @(
                        @{
                            "email" = $ToAddress
                            "name"  = $ToName
                        }
                    )
                    "subject" = $Subject
                }
            )
            "content"          = @(
                @{
                    "type"  = $MailBodyType
                    "value" = $MailBodyValue
                }
            )
            "from"             = @{
                "email" = $FromAddress
                "name"  = $FromName
            }
        }  # End $SendGridBody

    }  # End If Else

    $BodyJson = $SendGridBody | ConvertTo-Json -Depth 10
    $Header = @{
        "Authorization" = "Bearer $APIKey"
    }  # End $Header

    Invoke-RestMethod -Method POST -Uri "https://api.sendgrid.com/v3/mail/send" -Headers $Header -Body $BodyJson -ContentType "application/json"

}  # End Send-SendGridEmail
