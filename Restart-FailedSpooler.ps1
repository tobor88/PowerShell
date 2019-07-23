<#
.Synopsis
    Restart-FailedSpooler is a cmdlet created to restart the print spooler whenever a print job fails.
    This cmdlet was designed to run automatically through Task Scheduler and does not accept input.
    It can restart the Print Spooler on the print server and on the remote computer where the print job failed.

.DESCRIPTION
    The task for this cmdlet is executed when the event log PrintService Error 372, 350, or 314 happens.
    Once the event is triggered the print spooler on the server and the computer trying to print are restarted.

.NOTES
    Author: Rob Osborne 
    Alias: tobor
    Contact: rosborne@osbornepro.com
    https://roberthosborne.com

.EXAMPLE
   Restart-FailedSpooler

.EXAMPLE
   Restart-FailedSpooler -Verbose

#>

Function Restart-FailedSpooler {
    [CmdletBinding()]
        param()

    BEGIN {
    
        $ComputerIdentifier = "DESKTOP-*" # SET THIS VALUE TO IDENTIFY THE COMPUTER NAMING CONVENTION FOR YOUR ENVIRONMENT. * is a wildcard

        $LocalHost = $env:COMPUTERNAME

        $EventID = Get-WinEvent -LogName "Microsoft-Windows-PrintService/Admin" -MaxEvents 1 | Select-Object -ExpandProperty Id

        if ( ($EventID -eq 350) -or ($EventID -eq 314 ) ) {
        
            Write-Verbose "Event ID: $EventID `n`nPerforming print spooler restart on $LocalHost..." 
            
            Try {

                Get-Service "Print Spooler" | Restart-Service -Verbose

            } # End Try

            Catch {

                Write-Warning "Error Restarting Print Spooler"

            } # End Catch

        } # End if 

    } # End BEGIN

    PROCESS {

        if ($EventID -eq 372) {

            Try {

                Get-Service "Print Spooler" | Restart-Service -Verbose

            } # End Try

            Catch {

                Write-Warning "Error Restarting Print Spooler"

            } # End Catch
    
           $WordsInMessage = (Get-WinEvent -LogName "Microsoft-Windows-PrintService/Admin" -MaxEvents 1 | Select-Object -ExpandProperty Message | Out-String).Split(' ')

            foreach ($Word in $WordsInMessage) {
        
                if ($Word -like $ComputerIdentifier) {

                    Set-Variable -Name Fail -Value $Word

                    } # End If

            } # End foreach

            $FailedComputer = ($Fail.Replace('.',' ')).TrimEnd()

                Invoke-Command -ComputerName $FailedComputer -ScriptBlock {

                    Try {

                        Get-Service "Print Spooler" | Restart-Service -Verbose

                    } # End Try

                    Catch {

                        Write-Warning "Error Restarting Print Spooler"

                    } # End Catch

                } # End ScriptBlock

    } # End PROCESS

    END {

        Write-Verbose "Restarting Print Spoolers completed"

    } # End END

} # End Function

Restart-FailedSpooler -Verbose
