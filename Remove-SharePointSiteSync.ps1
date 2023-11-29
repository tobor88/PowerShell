Function Remove-SharePointSiteSync {
<#
.SYNOPSIS
This cmdlet is used to remove SharePoint site mappings from OneDrive synchronization in File Explorer


.DESCRIPTION
Remove SharePoint site(s) that are mapped in OneDrive syncrhonization in Windows File Explorer


.PARAMETER OrgName
Define the name of the Organization as it exists in %USERPROFILE%\<org-name>

.PARAMETER OneDriveExe
Define the aboslute path to the onedrive.exe executable. This is required to stop and start OneDrive

.PARAMETER SiteID
Define specific GUID values for the SharePoint Organization(s) you wish to stop synchronizing or use SiteID to use all discovered Site IDs

.PARAMETER SharePointSite
Define the name of the SharePoint site(s) you wish to stop synchronizing to File Explorer


.EXAMPLE
PS> Remove-SharePointSiteSync -OrgName contoso -SiteID "a99ff7f5-2e45-4335-b114-ea7f2114aaf8","1efd0efa-dbf6-4c99-afa5-a72fb1609e77" -SharePointSite "Name - Of Site", "IT Ops - Sys"
# This example removes the "Name - Of Site" SharePoint site from OneDrive's sync directories and stops synchronizing the site to Teams


.NOTES
Last Modified: 11/16/2023
Author: Robert H. Osborne
Alias: tobor
Contact: rosborne@osbornepro.com


.LINK
https://github.com/tobor88
https://github.com/osbornepro
https://www.powershellgallery.com/profiles/tobor
https://osbornepro.com
https://writeups.osbornepro.com
https://btpssecpack.osbornepro.com
https://www.powershellgallery.com/profiles/tobor
https://www.hackthebox.eu/profile/52286
https://www.linkedin.com/in/roberthosborne/
https://www.credly.com/users/roberthosborne/badges


.INPUTS
None


.OUTPUTS
None
#>
    [CmdletBinding(
        SupportsShouldProcess=$True,
        ConfirmImpact="Medium"
    )]  # End CmdletBinding
        param (
            [Parameter(
                Mandatory=$True,
                HelpMessage="[H] Enter the Azure organization name. This can be found in your $env:USERPROFILE directory `n[EXAMPLE] Contoso `n[INPUT] "
            )]  # End Parameter
            [ValidateNotNullOrEmpty()]
            [String]$OrgName,

            [Parameter(
                Mandatory=$False
            )]  # End Parameter
            [ValidateScript({Test-Path -Path $_})]
            [String]$OneDriveExe = "$env:ProgramFiles\Microsoft OneDrive\OneDrive.exe",

            [Parameter(
                Mandatory=$False
            )]  # End Parameter
            [ValidateScript({If ($_ -notlike "SiteID") {Try {[System.Guid]::Parse($_) | Out-Null; $True } Catch { $False }}})]
            [String[]]$SiteID = $(((Get-Content -Path (Get-Item -Path "$env:USERPROFILE\AppData\Local\Microsoft\OneDrive\settings\Business1\ClientPolicy_*.ini" -Force).FullName -Encoding Unicode | Select-String -Pattern 'SiteID' | Out-String).Trim().Split('=').Replace('{','').Replace('}','').Replace('SiteID','')) | ForEach-Object { If ($_ -notlike $Null) { $_.Trim() } } | Where-Object -FilterScript { $_ -notlike "" }), # Using 'SiteID' grabs all Site IDs for a company

            [Parameter(
                Mandatory=$True,
                HelpMessage="[H] Define the SharePoint Folder names to stop synchronizing. These are located in File Explorer under your Company SharePoint drive with the SharePoint Building icon `n[EXAMPLE] IT - General `n[INPUT] "
            )]  # End Parameter
            [String[]]$SharePointSite = 'IT Resources - EndPoint Deployments'
        )  # End param

    Write-Verbose -Message "[v] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Stopping OneDrive so changes can be made to sync options"
    Start-Process -FilePath $OneDriveExe -ArgumentList @("/shutdown") -Wait -ErrorAction Stop

    Write-Verbose -Message "[v] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Getting OneDrive client policy configuration info"
    $IniFiles = Get-Item -Path "$env:USERPROFILE\AppData\Local\Microsoft\OneDrive\settings\Business1\ClientPolicy_*.ini" -Force
    $MainIniFile = Get-Item -Path "$env:LOCALAPPDATA\Microsoft\OneDrive\settings\Business1\????????-????-????-????-????????????*.ini"

    Write-Verbose -Message "[v] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Deleting the registry mount information"
    $RegKey = Get-Item -Path "HKCU:\Software\Microsoft\OneDrive\Accounts\Business1\ScopeIdToMountPointPathCache"
    $UpdateFiles = @()

    ForEach ($IniFile in $IniFiles) {

        $SiteID | ForEach-Object {

            $IniFileContent = Get-Content -Path $IniFile.FullName -Encoding Unicode
            $ContainsSiteId = ($IniFileContent | Select-String -Pattern "$SiteID" | Out-String).Trim()
            If ($ContainsSiteId) {

                $UpdateFiles += $IniFile
                Write-Verbose -Message "[v] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') The site ID containing $SharePointSite is $ContainsSiteId"
                $SiteIdString = ($ContainsSiteId | Out-String).Split('=')[-1].Trim().Replace('{','').Replace('}','')

            }  # End If

            Remove-Variable -Name ContainsSiteId -Force -Verbose:$False -WhatIf:$False -ErrorAction SilentlyContinue | Out-Null

        }  # End ForEach-Object

    }  # End ForEach

    ForEach ($Property in $RegKey.Property) {

        $SPSiteObjId = $RegKey.GetValue($Property)
        ForEach ($SPSite in $SharePointSite) {

            If ($SPSiteObjId -like "*$($SPSite)") {
    
                Write-Verbose -Message "[v] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Successfully deleted the registry key value $SPSiteObjId associated with Site ID $SiteIdString"
                $IniContents = Get-Content -Path $MainIniFile -Encoding Unicode -Verbose:$False
                $SyncId = ($IniContents | Select-String -Pattern "(.*)Subscription(.*)" | Out-String).Trim()
                $SyncID = $SyncID.Split("$([System.Environment]::NewLine)") | ForEach-Object { If ($_ -like "*$Property*") { "$_" } }
                $NewIniContents = $IniContents.Replace("$SyncID","")
                $NewIniContent = ($NewIniContents.Split("$([System.Environment]::NewLine)") | ForEach-Object { If ($_ -notlike "*$Property*") { "$_" } }).Trim()
    
                Write-Verbose -Message "[v] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Removing $SiteIdString config from main policy sync ini file $($MainIniFile.FullName)"
                Set-Content -Path $MainIniFile.FullName -Value $NewIniContent -Encoding Unicode -Verbose:$False # WhatIf parameter will prevent this from running
                Try {
    
                    Write-Verbose -Message "[v] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Deleting policy INI file(s) $($UpdateFiles.FullName) which are associated with $SiteIdString"
                    Remove-Item -Path $UpdateFiles.FullName -Force -ErrorAction Stop # WhatIf parameter will prevent this from running
    
                } Catch {
    
                    Write-Verbose -Message "[v] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Ini file was removed after the policy config file removed the libary scope"
    
                }  # End Try Catch
    
                Remove-Item -Path $SPSiteObjId -Recurse -Force -ErrorAction SilentlyContinue | Out-Null # -WhatIf parameter will prevent this from running
                Break # Leave the ForEach loop
    
            } Else {
    
                Write-Verbose -Message "[v] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Site ID found is not the SharePoint site specified"
    
            }  # End If Else

        }  # End ForEach

    }  # End ForEach

    Write-Verbose -Message "[v] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Starting OneDrive back up"
    Start-Process -FilePath $OneDriveExe -ArgumentList @("/background")

}  # End Function Remove-SharePointSiteSync
