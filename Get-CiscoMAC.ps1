Function Get-CiscoMAC {
<#
.SYNOPSIS
This cmdlet is used to translate a MAC address into a grepable/include Cisco formatted MAC address


.DESCRIPTION
Convert a MAC address into a format that Cisco uses in its MAC Address table.


.PARAMETER MAC
Set the MAC address value you want converted to Cisco format


.EXAMPLE
Get-CiscoMAC -MAC ffffffffffff
# This example converts ffffffffffff to ffff.ffff.ffff

.EXAMPLE
Get-CiscoMAC -MAC ff-ff-ff-ff-ff-ff
# This example converts ff-ff-ff-ff-ff-ff to ffff.ffff.ffff

.EXAMPLE
Get-CiscoMAC -MAC ff.ff.ff.ff.ff.ff
# This example converts ff.ff.ff.ff.ff.ff to ffff.ffff.ffff

.EXAMPLE
Get-CiscoMAC -MAC ff:ff:ff:ff:ff:ff
# This example converts ff:ff:ff:ff:ff:ff to ffff.ffff.ffff


.NOTES
Author: Robert H. Osborne
Alias: tobor
Contact: rosborne@osbornepro.com


.INPUTS
System.String


.OUTPUTS
System.String


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
#>
    [CmdletBinding()]
        param(
            [Parameter(
                Position=0,
                Mandatory=$True,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$False,
                HelpMessage="Enter the MAC address you want to convert to Ciscos MAC format. `nEXAMLPE: ff:ff:ff:ff `nEXAMPLE:ffffffff `nEXAMPLE: ff.ff.ff.ff `nEXAMPLE: ff-ff-ff-ff")]  # End Parameter
            [String]$MAC)  # End param

    $Translate = $MAC.Replace(":","").Replace(".","").Replace("-","")
    
    ($Translate -Split '(....)' -ne '' -join '.').ToLower()
    Return

}  # End Function Get-CiscoMAC
