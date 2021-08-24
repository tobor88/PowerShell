<#
.SYNOPSIS
Restart-PrintSpooler is a cmdlet created to restart the print spooler whenever a print job failes.
This cmdlet was designed to run automatically.


.DESCRIPTION
The task for this cmdlet is executed when the event log PrintService Error 372, 350, and 314 happens.
Once the event is triggered the print spooler on the server and the computer trying to print are restarted.
This runs best as a task in task scheduler.


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
Restart-PrintSpooler -Pattern 'Desktop-' -User 'rob.osborne' -To alert@osbornepro.com -From alerter@osbornepro.com -SmtpServer mail.smtp2go.com

.EXAMPLE
Restart-PrintSpooler -Pattern 'Desktop-' -User 'rob.osborne' -To alert@osbornepro.com -From alerter@osbornepro.com -SmtpServer mail.smtp2go.com -Verbose

#>
Function Restart-PrintSpooler {
    [CmdletBinding()]
        param(
            [Parameter(Mandatory=$True,
                Position=0,
                ValueFromPipeLine=$True,
                ValueFromPipeLineByPropertyName=$True)]
            [string[]]$Pattern,

            [Parameter(Mandatory=$True,
                Position=1,
                ValueFromPipeLine=$True,
                ValueFromPipeLineByPropertyName=$True,
                HelpMessage="Enter a the administrators SamAccountName that is being used to Invoke-Command on the remote device attempting to print. Example: 'OP-")]
            [string[]]$User,

            [Parameter(Mandatory=$True,
                Position=2,
                ValueFromPipeLine=$True,
                ValueFromPipeLineByPropertyName=$True,
                HelpMessage="Enter the email address you want to send an alert email to if the print spooler service is down. Example: aler@osbornepro.com")]
            [System.Net.Mail.MailAddress]$To

            [Parameter(Mandatory=$True,
                Position=3,
                ValueFromPipeLine=$True,
                ValueFromPipeLineByPropertyName=$True,
                HelpMessage="Enter the email address that will send the alert email. Example: aler@osbornepro.com")]
            [System.Net.Mail.MailAddress]$From

            [Parameter(Mandatory=$True,
                Position=4,
                ValueFromPipeLine=$True,
                ValueFromPipeLineByPropertyName=$True,
                HelpMessage="Enter your SMTP Server to use for sending the email. Example: mail.smtp2go.com")]
            [Syste.Net.Mail.MailAddress]$SmtpServer,

            [Parameter(Mandatory=$True,
                Position=5,
                ValueFromPipeLine=$True,
                ValueFromPipeLineByPropertyName=$True,
                HelpMessage="Enter your domain name. Example: osbornepro.com")]
            [string[]]$Domain,
        ) # End param

        $EventID = Get-WinEvent -LogName Microsoft-Windows-PrintService/Admin -MaxEvents 1 | Select-Object -ExpandProperty 'Id'
        If ( ($EventID -eq 350) -or ($EventID -eq 314 ) ) {

            Write-Verbose "Event ID: $EventID `n`nPerforming print spooler restart on $env:COMPUTERNAME..."
            Restart-Service -Name "Print Spooler" -Force

            If ( (Get-Service -Name 'Print Spooler').Status  -ne 'Running' ) {

                Start-Service -Name 'Print Spooler'
                $Status = (Get-Service -Name 'Print Spooler').Status

                If ($Status -ne 'Running') {

                    $Body ="Print Spooler service status is in a state that is not running. `nCurrent State: $Status`n`Ensure the service gets back up and running."
                    Send-MailMessage -To $To -From $From -Subject "Print Spooler Issue on $env:COMPUTERNAME" -SmtpServer $SmtpServer -Priority 'Normal' -Body $Body

                    Get-Service -Name 'Print Spooler' | Restart-Service -Force

                } # End If

            } # End If
            Else {

                Write-Verbose "Successfully restarted print spooler on $env:COMPUTERNAME"

            } # End Else

        } # End If

        If ($EventID -eq 372) {

            Write-Verbose "Event ID: $EventID `n`nPerforming print spooler restart on $env:COMPUTERNAME..."
            Restart-Service -Name "Print Spooler" -Force

            If ( (Get-Service -Name 'Print Spooler').Status  -ne 'Running' ) {

                Start-Service -Name 'Print Spooler'
                $Status = (Get-Service -Name 'Print Spooler').Status
                If ($Status -ne 'Running') {

                    $Body ="Print Spooler service status is in a state that is not running. `nCurrent State: $Status`n`Ensure the service gets back up and running."
                    Send-MailMessage -To $To -From $From -Subject "Print Spooler Issue on $env:COMPUTERNAME" -SmtpServer $SmtpServer -Priority 'Normal' -Body $Body
                    Get-Service -Name 'Print Spooler' | Restart-Service -Force

                } # End If

            } # End If
             Else {

                Write-Verbose "Successfully restarted print spooler on $env:COMPUTERNAME"

            } # End Else

            Write-Host "If you do not have a password file you can get something to encrypt your password securely at https://github.com/tobor88/PowerShell/blob/master/Hide-PowerShellScriptPassword.ps1"
            $PasswordFile = "C:\Users\Public\Documents\Key.AESpassword.txt"
            $KeyFile = "C:\Users\Public\Documents\EncryptionKey"
            $Key = Get-Content -Path $KeyFile
            $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (Get-Content -Path $PasswordFile | ConvertTo-SecureString -Key $Key)
            $FailedComputer = (Get-WinEvent Microsoft-Windows-PrintService/Admin -MaxEvents 1 | Select-Object -ExpandProperty 'Message').Split(' ') | Select-String -Pattern $Pattern | Out-String

            Set-Variable -Name ComputerName -Value $FailedComputer.Trim()
            Invoke-Command -HideComputerName ("$ComputerName" + "$Domain") -ScriptBlock {

                Write-Verbose "Event ID: $EventID `n`nPerforming print spooler restart on $env:COMPUTERNAME..."
                Restart-Service -Name "Print Spooler" -Force

                If ( (Get-Service -Name 'Print Spooler').Status  -ne 'Running' ) {

                    Start-Service -Name 'Print Spooler'
                    $Status = (Get-Service -Name 'Print Spooler').Status
                    If ($Status -ne 'Running') {

                        $Body ="Print Spooler service status is in a state that is not running. `nCurrent State: $Status`n`Ensure the service gets back up and running."
                        Send-MailMessage -To $To -From $From -Subject "Print Spooler Issue on $env:COMPUTERNAME" -SmtpServer $SmtpServer -Priority 'Normal' -Body $Body
                        Get-Service -Name 'Print Spooler' | Restart-Service -Force

                    } # End If

                } # End If
                Else {

                    Write-Verbose "Successfully restarted print spooler on $env:COMPUTERNAME"

                } # End Else

            } -Credential $Cred -UseSSL # End ScriptBlock

        } # End If

        Write-Verbose "Restarting Print Spoolers completed"

} # End Function Restart-PrintSpooler
