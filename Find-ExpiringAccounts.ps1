<#
.SYNOPSIS
This cmdlet was created for Task Scheduler to find expiring accounts and alert the appropriate people.
I suggest having it run once every 2 or 3 days to receive at least 2 alerts before an account expires to prevent it
from happening if not desired.


.DESCRIPTION
This cmdlet finds accounts that are expiring in the next 10 days. It then sends an email alert in a nice table.


.NOTES
Author: Robert H. Osborne
Alias: tobor
Contact: rosborne@osbornepro.com


.LINK
https://osbornepro.com
https://writeups.osbornepro.com
https://btpssecpack.osbornepro.com
https://github.com/tobor88
https://gitlab.com/tobor88
https://www.powershellgallery.com/profiles/tobor
https://www.linkedin.com/in/roberthosborne/
https://www.credly.com/users/roberthosborne/badges
https://www.hackthebox.eu/profile/52286


.EXAMPLE
--------------- EXAMPLE 1 ------------------
PS> Find-ExpiringAccounts -Verbose

.INPUTS
None


.OUTPUTS
None
#>
Function Find-File {
    [CmdletBinding()]
        param() # End param

  BEGIN {

    $SmtpServer = mail.smtp2go.com
    $To = "hremailaddress@osbornepro.com","itemailaddress@osbornepro.com"
    $FromEmail = "from@osbornepro.com"
    $Accounts = Search-ADAccount -AccountExpiring -TimeSpan "10.00:00:00" | Select-Object -Property AccountExpirationDate, Name, @{ Label = "Manager"; E = { (Get-Aduser(Get-AdUser $_ -Property Manager).Manager).Name } }

  } # End BEGIN
  PROCESS {

    If (!($Accounts -eq $Null)) {

$Css = @"
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
"@

    $PreContent = "<Title>Expiring User Accounts (Next 10 Days)</Title>"
    $NoteLine = "$(Get-Date -Format 'MM/dd/yyyy HH:mm:ss')"
    $PostContent = "<br><p><font size='2'><i>$NoteLine</i></font>"

    $Body = $Accounts | ConvertTo-Html -Head $Css -PostContent $PostContent -PreContent $PreContent | Out-String

  } # End PROCESS

  END {

    ForEach ($ToEmail in $To) {

        Send-MailMessage -From $FromEmail -To $ToEmail -Subject "AD Event: Accounts Expiring" -BodyAsHtml -Body $Body -SmtpServer $SmtpServer

    } # End ForEach

  } # End END

} # End Function
