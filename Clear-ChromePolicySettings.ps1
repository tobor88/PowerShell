<#
.SYNOPSIS
This cmdlet was created to quickly remove Chrome policy settings that have been configured by group policy in the Windows Registry.


.DESCRIPTION
You can modify Chrome group policy settings however Chrome does not delete old ones or provide any way to implement changes for example with browser extensions when an organization changes products. Firefox handles Chrome group policy settings better than Chrome does which cracks me up because Cgrome made the settings.


.PARAMETER ComputerName
Defines the FQDN or hostname of a remote device you wish to clear the registry settings on using WinRM

.PARAMETER UseSSL
Switch parameter that indicates you want to use WinRM over HTTPS


.EXAMPLE
Clear-ChromePolicySettings
# This example clears the group policy settings that affect the Chrome browser

.EXAMPLE
Clear-ChromePolicySettings -ComputerName DESKTOP01.domain.com,DESKTOP02.domain.com
# This example clears the group policy settings that affect the Chrome browser on remote devices DESKTOP01 and DESKTOP02

.EXAMPLE
Clear-ChromePolicySettings -ComputerName DESKTOP01.domain.com,DESKTOP02.domain.com -UseSSL
# This example clears the group policy settings that affect the Chrome browser on remote devices DESKTOP01 and DESKTOP02 using WinRM over HTTPS


.NOTES
Author: Robert H. Osborne
Alias: tobor
Contact: rosborne@osbornepro.com


.LINK
https://osbornepro.com
https://writeups.osbornepro.com
https://btps-secpack.com
https://github.com/tobor88
https://gitlab.com/tobor88
https://www.powershellgallery.com/profiles/tobor
https://www.linkedin.com/in/roberthosborne/
https://www.youracclaim.com/users/roberthosborne/badges
https://www.hackthebox.eu/profile/52286


.INPUTS
None


.OUTPUTS
None

#>
Function Clear-ChromePolicySettings {
    [CmdletBinding(DefaultParameterSetName='Local')]
        param(
            [Parameter(
                ParameterSetName='Remote',
                Mandatory=$False,
                ValueFromPipeline=$False,
                HelpMessage="`n[H] Define the FQDN or remote Windows devices you wish to clear the Chrome policy settings on. `n[E] EXAMPLE: DESKTOP01.domain.com,DESKTOP02.domain.com")]  # End Parameter
            [String[]]$ComputerName,

            [Parameter(
                ParameterSetName='Remote',
                Mandatory=$False,
                ValueFromPipeline=$False)]  # End Parameter
            [Switch][Bool]$UseSSL

        )  # End param

    $DeleteRegItems = 'HKCU:\Software\Google\Chrome','HKCU:\Software\Policies\Google\Chrome','HKLM:\Software\Google\Chrome','HKLM:\Software\Policies\Google\Chrome','HKLM:\Software\Policies\Google\Update','HKLM:\Software\WOW6432Node\Google\Enrollment','HKLM:\Software\WOW6432Node\Google\Update\ClientState\{430FD4D0-B729-4F61-AA34-91526481799D}','C:\Program Files (x86)\Google\Policies'
    Switch ($PSCmdlet.ParameterSetName) {

        'Local' {

            Write-Verbose "Stopping open Chrome processes"
            Get-Process -Name chrome -ErrorAction SilentlyContinue | Stop-Process | Out-Null

            Write-Verbose "Removing Chrome Policy Settings from $env:COMPUTERNAME"
            Remove-Item -Path $DeleteRegItems -Recurse -Force -ErrorAction SilentlyContinue | Out-Null

            ForEach ($Path in $DeleteRegItems) {

                If ((Test-Path -Path $Path) -and ($Path -ne 'HKLM:\Software\Google\Chrome')) {

                    Write-Output "[!] FAILURE: $Path was unable to be deleted"

                }  # End If
                Else {

                    Write-Output "[*] SUCCESS: Deleted settings at $Path"

                }  # End Else

            }  # End ForEach

        }  # End Switch Local

        'Remote' {

            $Bool = $False
            If ($UseSSL.IsPresent) {

                $Bool = $True

            }  # End If

            Invoke-Command -HideComputerName $ComputerName -UseSSL:$Bool -ArgumentList $DeleteRegItems -ScriptBlock {

                Write-Verbose "Stopping open Chrome processes"
                Get-Process -Name chrome -ErrorAction SilentlyContinue | Stop-Process | Out-Null

                Write-Verbose "Removing Chrome Policy Settings from $env:COMPUTERNAME"
                Remove-Item -Path $Args -Recurse -Force -ErrorAction SilentlyContinue | Out-Null

                ForEach ($Path in $Args) {

                    If ((Test-Path -Path $Path) -and ($Path -ne 'HKLM:\Software\Google\Chrome')) {

                        Write-Output "[!] FAILURE: $Path was unable to be deleted"

                    }  # End If
                    Else {

                        Write-Output "[*] SUCCESS: Deleted settings at $Path"

                    }  # End Else

                }  # End ForEach

            }  # End ScriptBlock

        }  # End Switch Remote

    }  # End Switch

}  # End Function Clear-ChromePolicySettings
