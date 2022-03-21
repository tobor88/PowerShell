# REMOVE BUGGED OUTLOOK PROFILE
$Path = "HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\Profiles"
$OutlookProfiles = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue

Write-Output "Selection Options: `n"

If ($OutlookProfiles.Count -eq 0) {

    Write-Warning "There are no Outlook profiles to delete"
    $Name = Read-Host -Prompt "Enter a name for your new Outlook Profile: "
    $FullPath = $Path + $Name 

}  # End If
ElseIf ($OutlookProfiles.Count -gt 1) {

    For ($i = 0; $i -lt $OutlookProfiles.Count; $i++) {
        
        $ProfileName = $OutlookProfiles.Name.Replace('HKEY_CURRENT_USER\SOFTWARE\Microsoft\Office\16.0\Outlook\Profiles\','')[$i]
        $VarName = ($i + 1).ToString()

        New-Variable -Name $VarName -Value $ProfileName -Force
        Write-Output "`t$($VarName).) $ProfileName"

    }  # End For

    $Answer = Read-Host -Prompt "`nWhich Profile would you like to remove? EXAMPLE: 1"
    $Selection = ($Answer - 1).ToString()

    $Name = $OutlookProfiles.Name[$Selection] | Split-Path -Leaf
    $FullPath = ($OutlookProfiles.Name[$Selection]).Replace("HKEY_CURRENT_USER","HKCU:")

}  # End ElseIf
ElseIf ($OutlookProfiles.Count -eq 1) {

    $Name = $OutlookProfiles.Name | Split-Path -Leaf
    $FullPath = ($OutlookProfiles.Name).Replace("HKEY_CURRENT_USER","HKCU:")

}  # End Else
Else {

    Throw "[x] Lol No idea what you did. Preventing the rest of the scripts execution"

}  # End Else

Write-Output "[*] Attempting to delete the $Name Outlook profile"
Remove-Item -Path $FullPath -Recurse -Force -ErrorAction SilentlyContinue

If (!(Test-Path -Path $FullPath)) {

    Write-Host "[*] SUCCESS: Removed Outlook Profile $Name" -ForegroundColor Green

}  # End If
Else {

    Write-Warning "FAILED to Remove $Name Outlook profile!"

}  # End Else

# RE-CREATE OUTLOOK PROFILE
$OutlookProcess = Get-Process -Name Outlook -ErrorAction SilentlyContinue
 If ($OutlookProcess.Status -eq "Running") {

    $OutlookProcess | Stop-Process -Force | Out-Null

}  # End If

Write-Output "[*] Attempting to create profile $Name"
New-Item -Name $Name -Path $Path -Force -Verbose

Write-Output "Launcing Outlook with newly created profile"
Start-Process -FilePath Outlook -ArgumentList "/profile `"$Name`"" -ErrorAction SilentlyContinue
