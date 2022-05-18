<#
.SYNOPSIS
This cmdlet is used to export registry values from the Windows Registry


.DESCRIPTION
Export registry keys from the Windows Registry


.PARAMETER Path
Define the path to the registry key(s) you want to export

.PARAMETER ExportType
Define whether you want to export your information in CSV or XML format

.PARAMETER ExportPath
Define this parameter when ExportType is specified to define where you want to save a file

.PARAMETER NoBinary
Parameter is used to exclude binary data from your exported results


.EXAMPLE
Export-RegistryItem -Path HKCU:\Administrator -ExportType XML -ExportPath "$env:USERPROFILE\Downloads\RegBackup.xml"
# This example is used to export the defined registry value to an XML file

.EXAMPLE
$RegPaths = "HKLM:\SOFTWARE\Microsoft\SystemCertificates\MY\Certificates", "HKCU:\SOFTWARE\Microsoft\SystemCertificates\MY\Certificates"
$RegPaths | Export-RegistryItem -ExportType Csv -ExportPath "$env:USERPROFILE\Downloads\RegBackup.csv"
# This example is used to export the defined registry values to a CSV file


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
System.String
#>
Function Export-RegistryItem {
    [cmdletBinding()]
        param(
            [Parameter(
                Position=0,
                Mandatory=$True,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True,
                HelpMessage="Enter a registry path using the PSDrive format. ")]  # End Parameter
            [ValidateScript({
                # Unable to verify the registry paths specified
                (Test-Path -Path $_) -AND ((Get-Item -Path $_).PSProvider.Name -match "Registry"
            )})]  # End Parameter
            [String[]]$Path,

            [Parameter(
                ParameterSetName='ExportPath',
                Position=1,
                Mandatory=$True,
                ValueFromPipeline=$False,
                HelpMessage="Define the CSV or XML file type to export to. ")]  # End Parameter
            [ValidateSet("csv","xml")]
            [String]$ExportType,

            [Parameter(
                ParameterSetName='ExportPath',
                Position=2,
                Mandatory=$False,
                ValueFromPipeline=$False,
                HelpMessage="Specify the path to export the registry to." )]  # End Parameter
            [String]$ExportPath,

            [Parameter(
                Mandatory=$False)]  # End Parameter
            [Switch]$NoBinary

)  # End param

BEGIN {

    $Data = @()

}  # End BEGIN
PROCESS {

    Foreach ($Item in $Path) {
    
        $RegItem = Get-Item -Path $Item
        $Properties= $RegItem.Property

        If (!($Properties)) {

            $Value = $Null
            $PropertyItem = "(Default)"
            $RegType = "String"

            $Data += New-Object -TypeName PSCustomObject -Property @{
                Path=$Item
                Name=$PropertyItem
                Value=$Value
                Type=$RegType
                Computername=$env:COMPUTERNAME
            }  # End Property
        } Else {

            ForEach ($Property in $Properties) {

                $Value = $RegItem.GetValue($Property,$Null,"DoNotExpandEnvironmentNames")
                $RegType = $RegItem.GetValueKind($Property)
                $PropertyItem = $Property

                $Data += New-Object -TypeName PSCustomObject -Property @{
                    Path = $Item
                    Name = $PropertyItem
                    Value = $Value
                    Type = $RegType
                    Computername = $env:COMPUTERNAME
                }  # End Property

            }  # End ForEach

        }  # End If Else

    }  # End ForEach

}  # End PROCESS
END {

    If ($Data) {

        If ($NoBinary) {

            $Data = $Data | Where-Object -FilterScript { $_.Type -ne "Binary" }

        }  # End If

        If ($PsCmdlet.ParameterSetName -eq 'ExportPath') {

            Switch ($ExportType) {

                'csv' { $Data | Export-CSV -Path $ExportPath -NoTypeInformation }

                'xml' { $Data | Export-CLIXML -Path $ExportPath }

            }  # End Switch

        } Else {

            $Data

        }  # End If Else

    } Else {
        
        Write-Error "[x] No Data Found"

    }  # End If Else

}  # End END

}  # End Function Export-RegistryItem
