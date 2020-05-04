<#
.NAME
    Reset-BOFApplication


.SYNOPSIS
    Use this function to reset your BOF environment. This opens a closed Immunity Debugger and restarts the vulnerable service


.SYNTAX
    Reset-BOFApplication [-Name] <string> [-IDAPath] <string>


.PARAMETERS
    -Name <string[]>
        Specifies the service names of the services to restart. This should be the service vulnerable to the BOF.

            Required?                    true
            Position?                    0
            Default value                None
            Accept pipeline input?       True (ByPropertyName, ByValue)
            Accept wildcard characters?  true

    -IDAPath <string>
        Specifies a path to one or more locations. The default location is the current directory (.).

            Required?                    false
            Position?                    1
            Default value                Current directory
            Accept pipeline input?       False
            Accept wildcard characters?  false

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216).


.EXAMPLE
    -------------------------- EXAMPLE 1 --------------------------
    Reset-BOFApplication -Name "Sync Breeze Enterprise" -IDAPath "C:\Users\Public\Desktop\Immunity Debugger.lnk"
    This example resets the Sync Breeze service by its "Name: Sync Breeze Enterprise" and open immunity debugger from "C:\Users\Public\Desktop\Immunity Debugger.lnk"

    -------------------------- EXAMPLE 2 --------------------------
    Reset-BOFApplication "Sync Breeze Enterprise" "C:\Users\Public\Desktop\Immunity Debugger.lnk"
    This example resets the Sync Breeze service by its "Name: Sync Breeze Enterprise" and open immunity debugger from "C:\Users\Public\Desktop\Immunity Debugger.lnk"

    -------------------------- EXAMPLE 3 --------------------------
    Reset-BOFApplication -Name "Sync Breeze Enterprise"
    This example resets the Sync Breeze service by its "Name: Sync Breeze Enterprise" and open immunity debugger from "C:\Users\Public\Desktop\Immunity Debugger.lnk"

    
.DESCRIPTION
    IMPORTANT NOTE: I made this to spped up the process of testing a BOF in the PWK course. All this script does is restart a service if it is not running and opens Immunity Debuger.
    Also close out Immunity Debugger before running this script. This should display the still open PowerShell window for you to start everything up again. 


.INPUTS
    System.ServiceProcess.ServiceController, System.String
        You can pipe a service object or a string that contains a service name for this cmdlet.


.OUTPUTS
    None, System.ServiceProcess.ServiceController
        This cmdlet generates a System.ServiceProcess.ServiceController object that represents the restarted service, if you specify the PassThru parameter. Otherwise, this cmdlet does not generate any output.


.NOTES
    Author: Rob Osborne
    Alias: tobor
    Contact: rosborne@osbornepro.com
    https://roberthosborne.com


.LINK
    https://github.com/tobor88
    https://www.powershellgallery.com/profiles/tobor
    https://roberthosborne.com

#>
Function Reset-BOFApplication {
    [CmdletBinding()]
        param(
            [Parameter(
                Mandatory=$True,
                Position=0,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True,
                HelpMessage="Enter the name of the service you wish to restart. Example: Sync Breeze Enterprise")] # End Parameter
            [string]$Name,

            [Parameter(
                Mandatory=$True,
                Position=1,
                ValueFromPipeline=$False,
                ValueFromPipelineByPropertyName=$False,
                HelpMessage="Enter the path to Immunity Debuggers executable 'Immunity Debugger.lnk'. Example: C:\Users\Public\Desktop")] # End Parameter
            [string]$IDAPath
        )  # End param

BEGIN
{

    Write-Verbose "Obtaining current status info of service and IDA..."
    $Status = (Get-Service -Name $Name).Status
    $IDAProcess = (Get-Process -Name "ImmunityDebugger" -ErrorAction SilentlyContinue).ProcessName

}  # End BEGIN
PROCESS
{

    If ($Status -notlike 'Running')
    {

        Start-Service -Name $Name -Force

    }  # End If
    Else
    {

        Write-Output "$Name is already running. Restarting service $Name."

        Restart-Service -Name $Name -Force

    }  # End Else

    $CurrentStatus = (Get-Service -Name $Name).Status

    Start-Sleep -Seconds 1

    Write-Output "$Name Status: $CurrentStatus"

    If ($IDAProcess)
    {

        Write-Verbose "Closing Immunity Debugger"
        Stop-Process -Name "ImmunityDebugger" -Force

        Write-Verbose "Opening Immunity Deubugger"
        Start-Process -FilePath "$IDAPath\Immunity Debugger.lnk"

    }  # End If
    Else
    {

        Start-Process -FilePath "$IDAPath\Immunity Debugger.lnk"
        Set-Location -Path "$IDAPath"
        Write-Verbose "Starting Immunity Debugger from $IDAPath"

    }  # End Else

}  # End PROCESS

}  # End Function Reset-BOFApplication
