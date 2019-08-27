<#
.SYNOPSIS
    Get-UserSid is a cmdlet that is used to remove all old CA Certificates from a computer.

.SYNTAX
    Get-UserSid -SamAccountName <string[] SamAccountName>

.DESCRIPTION
    Translate a user's SamAccountName to an SID

.NOTES
    Author: Rob Osborne
    Alias: tobor
    Contact: rosborne@osbornepro.com
    https://roberthosborne.com

.INPUTS
    This cmdlet accepts value from the pipeline if it uses the property SamAccountName

.OUTPUTS
    This cmdlet returns a PSObject containing a users SID value.
    IsPublic    IsSerial    Name     BaseType
    --------    --------    ----    --------
    True        True        String  System.Object          

.EXAMPLE
    -----------------------EXAMPLES------------------------------
   Get-UserSid -SamAccountName -Verbose
   # The above example will translate a users SamAccountName to the SID value.

#>

Function Get-UserSid {
    [CmdletBinding()]
        param(
            [Parameter(Mandatory = $True,
                        Position = 0,
                        ValueFromPipeline=$True,
                        ValueFromPipelineByPropertyName=$True,
                        HelpMessage = "Enter a SamAccountName for the user profile. Example: OsbornePro\rob.osborne"
                        )] # End Parameter
            [string[]]$SamAccountName) # End param

    $ObjUser = New-Object System.Security.Principal.NTAccount($SamAccountName)

    $ObjSID = $ObjUser.Translate([System.Security.Principal.SecurityIdentifier])

    If (!($null -eq $ObjSID))
    {

        $ObjSID.Value

    } # End If
    Else
    {

        Write-Warning "SID Lookup failed."

    } # End Else

} # End Function Get-UserSid
