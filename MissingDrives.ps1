# This script can be used to map network shares automatically by having the task run on startup. It maps drive shares based on group memberships
$First,$Last = ($env:USERNAME).Split(".")
$DriveName = $First[0]+$Last
# DriveName is for mapping personal drives using the First Name Initial + Lastname naming context. Change to whatever you like

$DriveHashTable = @{}

$DriveHashTable.BullsShare = @()
$DriveHashTable.BullsShare += "C"
$DriveHashTable.BullsShare += "Bulls"
$DriveHashTable.BullsShare += "\\files.$env:USERDNSDOMAIN\Bulls$"
$DriveHashTable.BullsShare += "\\files\Bulls$"
$DriveHashTable.BullsShare += 'Michael Jordan', 'Scottie Pippen', 'Steve Kerr', 'Dennis Rodman', 'Ron Harper', 'Toni Kukoc'

$DriveHashTable.KnickShare = @()
$DriveHashTable.KnickShare += "N"
$DriveHashTable.KnickShare += "Knicks"
$DriveHashTable.KnickShare += "\\files.$env:USERDNSDOMAIN\Knicks$\$Drivename"
$DriveHashTable.KnickShare += "\\files\Knicks$\$Drivename"
$DriveHashTable.KnickShare += 'John Starks', 'Allan Houston', 'Patrick Ewing', 'Charles Oakley', 'Chris Childs', 'Charlie Ward'

$DriveHashTable.UserShare = @()
$DriveHashTable.UserShare += "U"
$DriveHashTable.UserShare += "Users Share Drive"
$DriveHashTable.UserShare += "\\files.$env:USERDNSDOMAIN\MyShare\$DriveName"
$DriveHashTable.UserShare += "\\files\MyShare\DriveName"

ForEach ($Drive in $DriveHashTable.Keys)
{

    $DrivesLetter = $DriveHashTable.$Drive.Item(0)
    $DrivesGroup = $DriveHashTable.$Drive.Item(1)
    $DriveLocation = $DriveHashTable.$Drive.Item(2)
    $DriveBackupLocation = $DriveHashTable.$Drive.Item(3)

    Write-Output "[*] Starting drive mapping check for $Drive"
    $GroupMembership = Get-WmiObject -Query "SELECT * FROM Win32_GroupUser WHERE GroupComponent=`"Win32_Group.Domain='$env:USERDNSDOMAIN',Name='$DrivesGroup'`""


    Write-Output "[*] Checking group membership"

    $GroupMembers = @()
    ForEach ($Item in $GroupMembership)
    {

        $Data = $Item.PartComponent -split "\,"
        $Name = ($Data[1] -split "=")[1]
        $GroupMembers += ("$Name`n").Replace("""","")

    }  # End ForEach

    If ($GroupMembers.Contains("$env:USERNAME") -or $GroupMembers.Contains("$env:USERNAME`n"))
    {

        If (!(Get-PsDrive -Name $DrivesLetter -ErrorAction 'SilentlyContinue') )
        {

            Try
            {

		            Write-Output "[*] Mapping drive $DriveLetter"
                New-PSDrive -Name $DrivesLetter -Root $DriveLocation -PSProvider 'FileSystem' -Persist -Scope 'Global' -ErrorAction 'SilentlyContinue'

            } # End try

            Catch
            {

		            Write-Output "[!] Failed to map $DriveLetter. Attempting backup location"
                New-PSDrive -Name $DrivesLetter -Root $DriveBackupLocation -PSProvider 'FileSystem' -Persist -Scope 'Global' -ErrorAction 'SilentlyContinue'

            } # End Catch

        } # End If

    }  # End If

}  # End ForEach
