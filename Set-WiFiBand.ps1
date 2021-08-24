<#
.SYNOPSIS
This cmdlet was created to quickly set the protocols for each wireless band to use. This can be used to set the protocols used by the 2.4GHz band and the 5GHz band.


.DESCRIPTION
This cmdlet is used to modify the 802.11 protocols used for the 2.4GHz and 5GHz bands on a computers WiFi adapter


.PARAMETER AdapterName
Specifies the network adapter interface name as an array. This parameter is here in case you have more than one WiFi adapter and you want to modify only one of the WiFi adapters or more than one if you have more than two.

.PARAMETER Standard
Define the 802.11 Standard you want to set the band to use.


.EXAMPLE
Set-WiFiBand -InterfaceIndex 11 -Band 2.4GHz -Standard
# This example decodes Base64 to a string in ASCII format


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
None

#>
Function Set-WiFiBand {
    [CmdletBinding()]
        param(
            [Parameter(
                Mandatory=$False,
                ValueFromPipeline=$False)]  # End Parameter
            [String[]]$AdapterName,

            [Parameter(
                Mandatory=$True,
                ValueFromPipeline=$False,
                HelpMessage="`n[H] Define the Wireless Standard you want to use on the selected WiFi band `n[E] EXAMPLE: ac")]  # End Parameter
            [ValidateSet('Disabled','802.11a','802.11b','802.11g','802.11n','802.11ac','802.11b/g','Dual Band 802.11a/g','Dual Band 802.11a/b/g')]
            [String]$Standard
        )  # End param


    If (!($AdapterName)) {

        $Adapter = Get-NetAdapter -Name "W*Fi*" | Select-Object -First 1

    }  # End If

    $802Values = Get-NetAdapterAdvancedProperty -Name $Adapter.Name | Where-Object -Property DisplayName -like "*802.11*" | Select-Object -Property "DisplayName","DisplayValue","RegistryValue","ValidDisplayValues","ValidRegistryValues"
    Switch ($Standard) {

        'Disabled' { $Standard = 'Disabled'}
        '802.11a' { $Standard = '1. 5GHz  802.11a'}
        '802.11b' { $Standard = '2. 2.4GHz 802.11b'}
        '802.11g' { $Standard = '3. 2.4GHz 802.11g'}
        '802.11n' { $Standard = '802.11n'}
        '802.11ac' { $Standard = '802.11ac'}
        '802.11b/g' { $Standard = '4. 2.4GHz 802.11b/g'}
        'Dual Band 802.11a/g' { $Standard = 'Dual Band 802.11a/g'}
        'Dual Band 802.11a/b/g' { $Standard = 'Dual Band 802.11a/b/g'}

    }  # End Switch

    ForEach ($V in $802Values) {

        If ($V.ValidDisplayValues.Count -ne 3) {

            $DisplayValue24 = $V.DisplayValue
            $Valid24Values = $V.ValidDisplayValues
            Write-Output "[*] Your current 2.4GHz band is set to use $DisplayValue24"

            If ($Valid24Values -Contains $Standard) {

                Set-NetAdapterAdvancedProperty -Name $Adapter.Name -DisplayName "Wireless Mode" -DisplayValue $Standard
                Write-Output "[*] Modifying $DisplayValue51 to $Standard"

            }  # End If

        }  # End If
        Else {

            $DisplayValue51 = $V.DisplayValue
            $Valid5Values = $V.ValidDisplayValues
            Write-Output "[*] Your current 5GHz band is set to use $DisplayValue51"

            If ($Valid5Values -Contains $Standard) {

                Set-NetAdapterAdvancedProperty -Name $Adapter.Name -DisplayName "Wireless Mode" -DisplayValue $Standard
                Write-Output "[*] Modifying $DisplayValue51 to $Standard"

            }  # End If

        }  # End Else

    }  # End ForEach

}  # End Function Set-WiFiBand
