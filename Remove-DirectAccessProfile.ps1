Function Remove-DirectAccessProfile {
    [CmdletBinding()]
        param(
            [Parameter(
                Position=0,
                Mandatory=$False,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True)]  # End Parameter
            [Alias('cn')]
            [String[]]$ComputerName
        )  # End param

    $RegPath = ‘HKLM:\Software\Policies\Microsoft\Windows NT\DNSClient\DnsPolicyConfig’
    Remove-Item -Path "$RegPath\*" -Recurse

}  # End Function Remove-DirectAccessProfile
