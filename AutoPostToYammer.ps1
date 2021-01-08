# This file is used to make a Yammer Announcement Post to a companys Yammer page. Great for doing Tech Tip of the Day or something like that. 
# This requires you to generate a developer token for Yammer. This token will be used to post an announcement to your Organziations Yammer page.


# Yammer Dev Token Generated from https://developer.microsoft.com/en-us/yammer
$DeveloperToken = "111111-AaAAa1AaAaAaaA1AAaa1aa" 

[datetime]$Format = Get-Date -Format MM/dd/yyyy
$TDate = $Format.ToShortDateString().ToString()

#--------------------------------------------------------------------------------------------------------------------------
# BELOW CREDENTIAL FILES CREATED USING https://github.com/tobor88/PowerShell/blob/master/Hide-PowerShellScriptPassword.ps1
#--------------------------------------------------------------------------------------------------------------------------
$PlainUser1 = "FromEmail@domain.com"
$PasswordFile1 = "C:\Users\Public\Documents\PwdHide\11111111111111111111.AESpassword.txt"
$KeyFile1 = "C:\Users\Public\Documents\PwdHide\11111111111111111111"
$Key1 = Get-Content -Path $KeyFile1
$Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $PlainUser1, (Get-Content -Path $PasswordFile1 | ConvertTo-SecureString -Key $Key1)
#----------------------------------------------------------------------------------------------------------------------------

# IMPORT CSV FILE DATA CONTAINING DATES IN FORMAT M/d/yyyy USING THE HEADERS Date AND Body
$CSVData = Import-Csv -Path "C:\users\Public\Documents\TechTipOfTheDay.csv" -Delimiter ","
$CSVData | ForEach-Object { 
    $CompDate = $_.Date
    If ($CompDate -eq $TDate) 
    { 
    
        $MBody = $_.Body 
    
    }  # End If 
        
}  # End ForEach

# Yammer Group ID https://www.yammer.com/api/v1/messages/in_group/{group-id}.json
$GroupID="11111111111"

$Uri="https://www.yammer.com/api/v1/messages.json"  
$Headers = @{ Authorization=("Bearer " + $DeveloperToken) }  
$Body=@{group_id="$GroupID"; body="$MBody"; message_type="announcement"; title="Technology Tip of the Day"; is_rich_text="true"; skip_body_notifications="true"; invited_user_ids=""}     

If ($Body.Body.Length -ne 0)
{

    Write-Verbose "Sending POST Request" 
    $WebRequest = Invoke-WebRequest –Uri $Uri –Method POST -Headers $Headers -Body $Body  


    Write-Verbose "Verifying Success or Failure"
    If ($WebRequest.StatusCode -eq 201) 
    {

        Write-Output "Message posted successfully."

    }  # End If
    Else 
    {

        $Body = "An error has occurred: " + $WebRequest.StatusCode.ToString().Trim() + " Description " + $WebRequest.Status.ToString().Trim()
        Send-MailMessage -From FromEmail@domain.com -To ToEamil@Domain.com -Subject "FAILURE: Yammer POST Failed $TDate" -Body $Body -UseSSL -Credential $Cred -Port 587 -SmtpServer smtp.office365.com -Priority High

    }  # End Else

}  # End If
