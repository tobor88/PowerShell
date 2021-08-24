<#
.SYNOPSIS
This cmdlet is used to force a replication between all Domain Controllers in a domain.


.DESCRIPTION
Execute this cmdlet on a domain joined computer. The DC will need to be accessible using
WinRM port 5985 or WinRM over HTTPS port 5986. The DC will be discovered automatically
and the repl command will be exceuted to start the DC replication.


.PARAMETER UseSSL
This parameter is used to communicate with the remote Domain Controllers using WinRM over HTTPS
on port 5986 as opposed to WinRM on port 5985.

.PARAMETER SkipAllCertChecks
This parameter is a session option that gets used to disregard any certificate validation errors
for an environment where the CN is not set correctly.
# Verifiy a certificate thumbprint used on port 5986:
    winrm enum winrm/config/listener


.EXAMPLE
Invoke-DCReplication
This examples executes a DC replicaiton to all DCs over port 5985

.EXAMPLE
Invoke-DCReplication -UseSSL
This examples executes a DC replicaiton to all DCs over port 5986

.EXAMPLE
Invoke-DCReplication -UseSSL -SkipAllCertChecks
This examples executes a DC replicaiton to all DCs over port 5986 and ignores certificate errors


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


.INPUTS
None


.OUTPUTS
System.Management.Automation.PSRemotingJob, System.Management.Automation.Runspaces.PSSession, or the output of the
invoked command
This cmdlet returns a job object, if you use the AsJob parameter. If you specify the InDisconnectedSession
parameter, Invoke-Command returns a PSSession object. Otherwise, it returns the output of the invoked command,
which is the value of the ScriptBlock parameter.
#>
Function Invoke-DCReplication {
    [CmdletBinding(DefaultParameterSetName="NoSSL")]
        param(
            [Parameter(
                Mandatory=$True,
                ParameterSetName="UseSSL")]  # End Parameter
            [Switch][Bool]$UseSSL,

            [Parameter(
                Mandatory=$False,
                ParameterSetName="UseSSL")]  # End Parameter
            [Switch][Bool]$SkipAllCertChecks
        )  # End param

BEGIN {

    Write-Verbose "Collecting Domain Information"

    $DomainInfo = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
    $PDC = $DomainInfo.PdcRoleOwner.Name
    $Domain = $DomainInfo.Forest.Name
    $AllDCs = $DomainInfo.DomainControllers.Name
    $DomainDN = $DomainInfo.DomainControllers.Partitions[0]

}  # End BEGIN
PROCESS {

    Try {

        If ($UseSSL.IsPresent) {

            Write-Verbose "Use of WinRM over SSL was specified"
            If ($SkipAllCertChecks.IsPresent) {

                Write-Verbose "Ignore certificate warning was specified"
                $SessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck

                Invoke-Command -ArgumentList $DomainDN,$AllDCs -HideComputerName $PDC -UseSSL -SessionOption $SessionOption -ScriptBlock {

                    $Args[1] | Foreach-Object { Write-Output "[*] Performing replication on $_"; (repadmin /syncall $_ $Args[0] /AdeP) | Out-Null }

                }  # End Invoke-Command

            }  # End If
            Else {

                Invoke-Command -ArgumentList $DomainDN,$AllDCs -HideComputerName $PDC -UseSSL -ScriptBlock {

                    $Args[1] | Foreach-Object { Write-Output "[*] Performing replication on $_"; (repadmin /syncall $_ $Args[0] /AdeP) | Out-Null }

                }  # End Invoke-Command

            }  # End Else

        }  # End If
        Else {

            Write-Verbose "Using WinRM port over port 5985"
            Invoke-Command -ArgumentList $DomainDN,$AllDCs -HideComputerName $PDC -ScriptBlock {

                $Args[1] | Foreach-Object { Write-Output "[*] Performing replication on $_"; (repadmin /syncall $_ $Args[0] /AdeP) | Out-Null }

            }  # End Invoke-Command

        }  # End Else
    }  # End Try
    Catch {

        Write-Error "There was an issue replicating to a domain controller"
        $Error[0]

    }  # End Catch

}  # End PROCESS
END {

    Write-Verbose "Verifying occurence off the last successful replication"
    If ($UseSSL.IsPresent) {

        If ($SkipAllCertChecks.IsPresent) {

            Write-Verbose "Executing command over WinRM over HTTPS and ignoring certification warnings"
            Invoke-Command -ArgumentList $Domain -HideComputerName $PDC -UseSSL -SessionOption $SessionOption -ScriptBlock {

                Get-ADReplicationPartnerMetadata -Target "$Args" -Scope Domain | Select-Object -Property "Server","LastReplicationSuccess" | Format-Table -AutoSize

            }  # End Invoke-Command

        }  # End If
        Else {

            Write-Verbose "Executing command over WinRM over HTTPS"
            Invoke-Command -ArgumentList $Domain -HideComputerName $PDC -UseSSL -ScriptBlock {

                Get-ADReplicationPartnerMetadata -Target "$Args" -Scope Domain | Select-Object -Property "Server","LastReplicationSuccess" | Format-Table -AutoSize

            }  # End Invoke-Command

        }  # End Else

    }  # End If
    Else {

        Write-Verbose "Executing command over WinRM"
        Invoke-Command -ArgumentList $Domain -HideComputerName $PDC -ScriptBlock {

            Get-ADReplicationPartnerMetadata -Target "$Args" -Scope Domain | Select-Object -Property "Server","LastReplicationSuccess"

        }  # End Invoke-Command

    }  # End Else

}  # End END

}  # End Function Invoke-DCReplication
