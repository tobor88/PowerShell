<#
.SYNOPSIS
This cmdlet is used to import registry values from a CSV or XML file


.DESCRIPTION
Import registry data from a CSV or XML file


.PARAMETER Path
Define the path(s) to the CSV or XML file containing the registry items to import

.PARAMETER Overwrite
Specify this switch parameter to overwrite any existing registry entries


.EXAMPLE
Import-Registry -Path "$env:USERPROFILE\Downloads\RegBackup.xml"
# This example is used to import the defined registry XML file

.EXAMPLE
Import-Registry -Path "$env:USERPROFILE\Downloads\RegBackup.csv"
# This example is used to import the defined registry CSV file


.NOTES
Author: Robert H. Osborne
Alias: tobor
Contact: rosborne@osbornepro.com


.LINK
https://osbornepro.com
https://btpssecpack.osbornepro.com
https://writeups.osbornepro.com
https://github.com/OsbornePro
https://gitlab.com/tobor88
https://www.powershellgallery.com/profiles/tobor
https://www.hackthebox.eu/profile/52286
https://www.linkedin.com/in/roberthosborne/
https://www.credly.com/users/roberthosborne/badges


.INPUTS
System.String System.Array


.OUTPUTS
System.Management.Automation.PSCustomObject
    `Import-RegistryItem` returns a custom object that contains the new property(s).
#>
Function Import-RegistryItem {
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='High')]
        param(
            [Parameter(
                Position=0,
                Mandatory=$True,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$False,
                HelpMessage="Define the CSV or XML file path containing the registry items to import." )]  # End Parameter
            [ValidateScript({
                # Unable to verify the registry paths specified
                ((Test-Path -Path $_) -and (($_ -like "*.csv") -or ($_ -like "*.xml")))
            })]  # End Parameter
            [String[]]$Path,

            [Parameter(
                Mandatory=$False)]  # End Parameter
            [Switch][bool]$Overwrite

        )  # End param

    [bool]$Overwrite = $PSBoundParameters.ContainsKey('Overwrite')

    If ($Path -like "*.xml") {
    
        $ImportItems = Import-Clixml -Path $Path

    } Else {

        $ImportItems = Import-Csv -Path $Path

    }  # End If Else

    $ImportItems | ForEach-Object {

        If ($PSCmdlet.ShouldProcess(("Overwritting existing registry items. `n$(Get-Content -Path $Path)"),
                        ("Would you like to overwrite these registry items? `n$(Get-Content -Path $Path)"),
                        "Modifying registry items")
        ) {

            New-ItemProperty -Path $_.Path -Name $_.Name -Value $_.Value -PropertyType $_.Type -Force:$Overwrite

        }  # End If

    }  # End ForEach-Object

}  # End Function Import-RegistryItem
