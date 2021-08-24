<#
.SYNOPSIS
This cmdlet is used to get a battery report for a local or remote device


.DESCRIPTION
Generate an HTML report on the battery of a local or remote Windows Device


.PARAMETER ComputerName
This parameter is used to define the name of a remote computer you want battery information from

.PARAMETER Path
This parameter indicates the location to save the HTML report. The default location is $env:USERPROFILE\Documents\BatteryReport.html

.PARAMETER UseSSL
This parameter indicates that you when communicating with a remote device you want to use WinRM over HTTPS instead of WinRM


.EXAMPLE
Get-BatteryReport -Path C:\Users\user\Documents\BatteryReport.html
# This example saves the battery report for the local machine to $env:USERPROFILE\Documents\BatteryReport.html

.EXAMPLE
Get-BatteryReport -ComputerName Laptop01.domain.com -Path $env:USERPROFILE\Documents\BatteryReport.html -UseSSL
# This examples saves the battery report for remote device Laptop01.domain.com to \\$env:COMPUTERNAME\C$\Users\user\Documents\BatteryReport.html. This communication happens using WinRM over HTTPS

.EXAMPLE
Get-BatteryReport
# This example saves the battery report for the local machine to $env:USERPROFILE\Documents\BatteryReport.html


.NOTES
Author: Robert H. Osborne
Alias: tobor
Contact: rosborne@osbornepro.com


.INPUTS
None


.OUTPUTS
None


.LINK
https://osbornepro.com
https://writeups.osbornepro.com
https://btpssecpack.osbornepro.com
https://github.com/OsbornePro
https://gitlab.com/tobor88
https://www.powershellgallery.com/profiles/tobor
https://www.linkedin.com/in/roberthosborne/
https://www.credly.com/users/roberthosborne/badges
https://www.hackthebox.eu/profile/52286

#>
Function Get-BatteryReport {
    [CmdletBinding(DefaultParameterSetName='Local')]
        param(
            [Parameter(
                ParameterSetName='Remote',
                Mandatory=$True,
                ValueFromPipeline=$False,
                HelpMessage="`n[H] Enter the computer name you want to generate a battery report on. Separate multiple values with a comma. `n[E] EXAMPLE: Laptop01.domain.com")]  # End Parameter
            [String[]]$ComputerName,

            [Parameter(
                Mandatory=$False,
                ValueFromPipeline=$False
            )]  # End Parameter
            [ValidateScript({($_ -like "*.html") -or ($_ -like "*.htm")})]
            [String]$Path = "$env:USERPROFILE\Documents\BatteryReport.html",

            [Parameter(
                ParameterSetName='Remote',
                Mandatory=$False,
                ValueFromPipeline=$False)]  # End Parameter
            [Switch][Bool]$UseSSL

        )  # End param

    Switch ($PsCmdlet.ParameterSetName) {

        'Remote' {

            $Bool = $False
            If ($UseSSL.IsPresent) {

                Write-Verbose "WinRM over HTTPS communication will be used to execute command"
                $Bool = $True

            }  # End If

            ForEach ($C in $ComputerName) {

                Write-Verbose "Obtaining battery report from $C and saving it to $Path"
                Invoke-Command -HideComputerName $C -ArgumentList $Path -UseSSL:$Bool -ScriptBlock {

                    cmd /c powercfg /batteryreport /output $Args[0]

                }  # End ScriptBlock

            }  # End ForEach

        }  # End Switch Remote

        'Local' {

            Write-Verbose "Obtaining battery report from $env:COMPUTERNAME and saving it to $Path"
            cmd /c powercfg /batteryreport /output $Path

        }  # End Switch Local

    }  # End Switch

}  # End Function Get-BatteryReport
