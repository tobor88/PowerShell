<#
.Synopsis
    Get-ExpiringPasswords is a cmdlet created to alert users if they have a password expiring in the next 14 days or less.
    It was made to run on Task Scheudler. I suggest having it run once every 2 or 3 days on a domain controller.

.DESCRIPTION
    This cmdlet Get-ExpiringPasswords finds users who have passwords expiring in 14 days or less and sends them an email.
    Your email body should be edited to explain to users how to change their passwords in different situations if they exist.

.NOTES
    Author: Rob Osborne 
    Alias: tobor
    Contact: rosborne@osbornepro.com
    https://roberthosborne.com

.EXAMPLE
   Get-ExpiringPasswords

.EXAMPLE
   Get-ExpiringPasswords -Verbose
#>

Function Get-ExpiringPasswords {
    [CmdletBinding()]
        param() # End param

    BEGIN {
    
$Css1 = @"
<style>
table {
    font-family: verdana,arial,sans-serif;
        font-size:11px;
        color:#333333;
        border-width: 1px;
        border-color: #666666;
        border-collapse: collapse;
}
th {
        border-width: 1px;
        padding: 8px;
        border-style: solid;
        border-color: #666666;
        background-color: #dedede;
}
td {
        border-width: 1px;
        padding: 8px;
        border-style: solid;
        border-color: #666666;
        background-color: #ffffff;
}
</style>
"@ # End CSS 

        $SmtpServer = "SmtpServer.com"
        
        $FromEmail = "from@osbornepro.com"
        
        $MaxPassAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge.Days

        $TodaysDate = Get-Date

        $UserDetails = Get-ADUser -Filter { Enabled -eq $True -and PasswordNeverExpires -eq $False } –Properties * | Select-Object -Property "Displayname","Mail", @{l="ExpiryDate";e={$_.PasswordLastSet.AddDays($MaxPassAge)}}

    } # End BEGIN
  
    PROCESS {

        foreach ($Users in $UserDetails) {

            $ExpirationDate = $Users.ExpiryDate 

            if ($ExpirationDate -eq $TodaysDate) {

                $ToWhom = $Users.DisplayName

                $PreContent1 = "<Title>ALERT: Password Has Expired</Title>"

                $NoteLine1 = "This Message was Sent on $(Get-Date -format 'MM/dd/yyyy HH:mm:ss') from IT as a friendly reminder."

                $PostContent1 = "<br><p><font size='2'><i>$NoteLine</i></font>"

                $MailBody1 = $Users | ConvertTo-Html -Head $Css1 -PostContent $PostContent1 -PreContent $PreContent1 -Body "Attention $ToWhom, <br><br>If you have received this email your account password has expired. <br><br>To reset your password click <a href='https://account.activedirectory.windowsazure.com/ChangePassword.aspx'>HERE</a> <br><br> Or if you are in the office press Ctrl+Alt+Del and click the Change Password button. You will not be able to connect to the VPN until your password is reset using either of these methods. <br><br><hr><br>" | Out-String
        
                $From1 = $Users.Mail | Out-String

                try {

                    Send-MailMessage -From $FromEmail -To $From1 -Subject "Your Account Password Has Expired" -BodyAsHtml -Body $MailBody1 -SmtpServer $SmtpServer -Priority High
        
                } # End Try

                catch {

                    Send-MailMessage -From $FromEmail -To $From1 -Subject "Your Account Password Has Expired" -BodyAsHtml -Body $MailBody1 -SmtpServer $SmtpServer -Priority High

                    Send-MailMessage -From $FromEmail -To $FromEmail -Subject "Forward This Email Alert to $From1. Auto Send Failed" -BodyAsHtml -Body $MailBody1 -SmtpServer $SmtpServer

                } # End Catch
  
            } # End if
            
    } # End PROCESS

    END {

            if (($TodaysDate -ge $ExpirationDate.AddDays(-14)) -and ($TodaysDate -le $ExpirationDate)) {

                $PreContent = "<Title>Password Expiring in 14 days or less</Title>"

                $NoteLine = "This Message was Sent on $(Get-Date -format 'MM/dd/yyyy HH:mm:ss') from IT as a friendly reminder."

                $PostContent = "<br><p><font size='2'><i>$NoteLine</i></font>"

                $ToWho = $Users.DisplayName

                $MailBody = $Users | ConvertTo-Html -Head $Css -PostContent $PostContent -PreContent $PreContent -Body "Attention $ToWho, <br><br>If you have received this email your password is expiring in 14 days or less. Reset your password before it expires. <br><br>If you are on your home internet you can change your password by performing the following steps. <br><br>    <h4>Change Password From Home Steps</h4><strong>1.)</strong> Connect to the VPN. If you are not connected to the VPN, your password change will not take effect and it will cause issues for you. <br>    <strong>2.)</strong> Press Ctrl+Alt+Del and select the 'Change Password' Button. <br>    <strong>3.)</strong> Enter a new password. Your new password needs to be at least 8 characters long and contain a lowercase letter, uppercase letter, and a number or special character. <br><br>If you are changing your password from your desktop the previous rules apply; only do not connect to the VPN on your desktop as you are already on our network. <br><br><strong>NOTE:</strong> Be sure to sign into your laptop while you are in the office after you have changed your password. This is to ensure the laptop is aware your password has changed before you take it home. <br>You are also able to change your password <a href='https://account.activedirectory.windowsazure.com/ChangePassword.aspx'>HERE: Change Password Link</a> <br><hr><br>" | Out-String

                $From = $Users.Mail | Out-String

                try {

                    Send-MailMessage -From $FromEmail -To $From -Subject "Your Account Password is Expiring Soon" -BodyAsHtml -Body $MailBody -SmtpServer $SmtpServer -Priority Normal
        
                } # End Try

                catch {

                    Send-MailMessage -From $FromEmail -To $From -Subject "Your Account Password is Expiring Soon" -BodyAsHtml -Body $MailBody -SmtpServer $SmtpServer -Priority Normal

                    Send-MailMessage -From $FromEmail -To $FromEmail -Subject "Forward This email to $From. Auto Send Failed" -BodyAsHtml -Body $MailBody -SmtpServer $SmtpServer

                } # End Catch

            } # End Elseif

            else {

                Write-Verbose "No passwords expiring in the next 14 days or less."

            } # End Else
 
        } # End Foreach
        
    } # End END

} # End Function

Get-ExpiringPasswords -Verbose
