<#
.Synopsis
    Find-ExpiringAccounts is a cmdlet created for Task Scheduler to find expiring accounts and alert the appropriate people.
    I suggest having it run once every 2 or 3 days to receive at least 2 alerts before an account expires to prevent it 
    from happening if not desired.
    
.DESCRIPTION
    This cmdlet finds accounts that are expiring soon and can alert through email this is happening in the next 10 days.

.NOTES
    Author: Rob Osborne 
    Alias: tobor
    Contact: rosborne@osbornepro.com
    https://roberthosborne.com

.EXAMPLE
   Find-ExpiringAccounts

.EXAMPLE
   Find-ExpiringAccounts -Verbose
#>

Function Find-File {
    [CmdletBinding()]
        param() # End param

  BEGIN {

    $SmtpServer = <Smtp_Server>
    
    $To = "hremailaddress@osbornepro.com","itemailaddress@osbornepro.com"
    
    $FromEmail = "from@osbornepro.com"

    $Accounts = Search-ADAccount -AccountExpiring -TimeSpan "10.00:00:00" | Select-Object -Property AccountExpirationDate, Name, @{ Label = "Manager"; E = { (Get-Aduser(Get-AdUser $_ -Property Manager).Manager).Name } }

  } # End BEGIN

  PROCESS {

    if (!($Accounts -eq $Null)) {

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

    $PreContent = "<Title>Expiring Users (Next 10 Days)</Title>"

    $NoteLine = "$(Get-Date -format 'MM/dd/yyyy HH:mm:ss')"

    $PostContent = "<br><p><font size='2'><i>$NoteLine</i></font>"
  
    $Body = $Accounts | ConvertTo-Html -Head $Css -PostContent $PostContent -PreContent $PreContent | Out-String

  } # End PROCESS

  END { 

    ForEach ($ToEmail in $To) {
    
      Send-MailMessage -From $FromEmail -To $ToEmail -Subject "AD Event: Accounts Expiring" -BodyAsHtml -Body $Body -SmtpServer $SmtpServer
    
    } # End Foreach loop
  
  } # End END
  
} # End Function
