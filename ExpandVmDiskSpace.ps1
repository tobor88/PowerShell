# This script can be used to expand the size of C drive on a device when the vSphere hosts datastore has more than 15% space free to perform the expansion
# If the datastore has less than 15% free space you will get an email if you define the email values when prompted

$Credential = Get-Credential -Message "Enter your vSphere admin credentials"
$SmtpServer = Read-Host -Prompt "If you are going to use the send email feature, enter your SMTP server: "
If ($SMTPServer.Length -gt 2) {

    $To = Read-Host -Prompt "Enter your TO email address: "
    $From = Read-Host -Prompt "Enter your FROM email address: "
    $MailCred = Read-Host -Rrompt "Enter your email credentials"

}  # End If

[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls11,Tls12'


# Get-VMWareDatastoreSize
Function Get-VMWareDatastoreSize {
    [CmdletBinding(DefaultParameterSetName="Credential")]
        param(
            [ValidateNotNull()]
            [System.Management.Automation.PSCredential]
            [System.Management.Automation.Credential()]
            [Parameter(ParameterSetName="Credential")]
            $Credential = [System.Management.Automation.PSCredential]::Empty,

            [Parameter(
                ParameterSetName="BasicAuth",
                Position=0,
                Mandatory=$True,
                ValueFromPipeline=$False,
                HelpMessage="Enter the username to authenticate to the vSphere server with. EXAMPLE: mr.derp")]  # End Parameter
            [String]$Username,

            [Parameter(
                ParameterSetName="BasicAuth",
                Position=1,
                Mandatory=$True,
                ValueFromPipeline=$False,
                HelpMessage="Enter the password for the vSphere user account you defined. EXAMPLE: Password123!")]  # End Parameter
            [SecureString]$Password,

            [Parameter(
                Position=1,
                Mandatory=$False,
                ValueFromPipeline=$False,
                HelpMessage="Define the vSphere server to expand this disk on. EXAMPLE: vsphere.domain.com")]  # End Parameter
            [ValidateScript({Test-Connection -BufferSize 32 -Count 2 -ComputerName $_ -Quiet})]
            [String[]]$Server,

            [Parameter(
                Position=2,
                Mandatory=$False,
                ValueFromPipeline=$False
                #HelpMessage="Enter the security group(s) required to authenticate to the vSphere servers `nEXAMPLE: DOMAIN\vSphere Admins "
            )]  # End Parameter
            [String[]]$Group,

            [Parameter(
                Mandatory=$False,
                ValueFromPipeline=$False,
                HelpMessage="Increase the size of the low space disk by this many GigaBytes (50Gb limit). `nEXAMPLE: 30")]  # End Parameter
            [Switch][Bool]$SendEmailNotification,

            [Parameter(
                ParameterSetName='BasicAuth',
                Mandatory=$False
            )]  # End Parameter
            [Switch][Bool]$UseBasicAuth
        )  # End param

    If (!(Test-Connection -BufferSize 32 -ComputerName 1.1.1.1 -Count 2 -Quiet)) {
           
        Throw "[x] NO INTERNET: This cmdlet requires internet. "

    }  # End If

    Write-Verbose "Verifying vSphere group membership"
    $CurrentUserId = [Security.Principal.WindowsIdentity]::GetCurrent()
    $GroupMembership = $CurrentUserId.Groups | ForEach-Object {

        $_.Translate([Security.Principal.NTAccount])

    }  # End ForEach-Object

    ForEach ($G in $Group) {

        If (!($GroupMembership.Value.Contains($G))) {

            Throw "[x] $($CurrentUserId.Name) does not have permissions to access vSphere"

        }  # End If

    }  # End ForEach

    If ((Get-PackageProvider -Name Nuget).Version -lt 2.8.5.201) {

        Try {

            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$False

        } Catch {

            Throw $Error

        }  # End Try Catch

    }  # End If

    Write-Verbose "Installing required modules"
    $ModuleNames = "VMWare.PowerCLI","VMWare.VimAutomation.Core"
    If (!(Get-Module -ListAvailable -Name $ModuleNames -Verbose:$False)) {

        Write-Verbose "Installing VMWare.PowerCLI module"
        Install-Module -Name $ModuleNames -Force -Confirm:$False -Verbose:$False

    }  # End If

    Write-Verbose "Importing required modules"
    Import-Module -Name $ModuleNames -Force -Verbose:$False -ErrorAction Stop

    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -ParticipateInCeip $False -DisplayDeprecationWarnings $False -Scope AllUsers -Confirm:$False | Out-Null

    ForEach ($VIServer in $Server) {

        Write-Verbose "Connecting to $VIServer"
        Try {
       
            If ($PSCmdlet.ParameterSetName -eq 'Credential') {

                Write-Verbose "Connecting using -Credential specified"
                Connect-VIServer -Server $VIServer -Credential $Credential -Force -ErrorAction Stop | Out-Null

            } ElseIf ($UseBasicAuth.IsPresent) {

                Write-Verbose "Connecting using Basic Authentication"
                $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)))
                Connect-VIServer -Server $VIServer -User $Username -Password $Password -Force -ErrorAction Stop | Out-Null
                Remove-Variable -Name Password

            } Else {
       
                Write-Verbose "Connecting using a manual credential object"
                $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($Username, $Password)
                Connect-VIServer -Server $VIServer -Credential $Credential -Force -ErrorAction Stop | Out-Null

            }  # End If ElseIf Else
             
        } Catch {

            Throw "[x] Could not connect to vCenter $VIServer"

        }  # Try Catch

        Write-Verbose "Getting the size of vsphere data stores"
        $VM = Get-VM -Name "$env:COMPUTERNAME.$((Get-CimInstance -ClassName Win32_ComputerSystem).Domain)" -ErrorAction Stop
        $Results = Get-Datastore -VM $VM.Name -ErrorAction Stop | Select-Object -Property @{N="DataStoreName";E={$_.Name}},@{N="Percentage Free Space(%)";E={[math]::Round(($_.FreeSpaceGB)/($_.CapacityGB)*100,2)}}
        $Results = $Results | Where-Object -FilterScript { $_.'Percentage Free Space(%)' -le 15 } | Select-Object -Property 'DataStoreName','Percentage Free Space(%)'
        If ($Results -and $SendEmailNotification.IsPresent) {

            $Css = @"
<style>
table {
    font-family: verdana,arial,sans-serif;
        font-size:11px;
        color:#333333;
        border-width: 1px;
        border-color: #666666;
        border-collapse: collapse;
}
th {
        border-width: 1px;
        padding: 8px;
        border-style: solid;
        border-color: #666666;
        background-color: #dedede;
}
td {
        border-width: 1px;
        padding: 8px;
        border-style: solid;
        border-color: #666666;
        background-color: #ffffff;
}
</style>
"@ # End CSS

            $PreContent = "<Title>NOTIFICATION: Low Datastore Disk Space</Title>"
            $NoteLine = "This Message was Sent on $(Get-Date -Format 'MM/dd/yyyy HH:mm:ss')"
            $PostContent = "<br><p><font size='2'><i>$NoteLine</i></font>"
            $MailBody = $Results | ConvertTo-Html -Head $Css -PostContent $PostContent -PreContent $PreContent -Body "<br>$($env:COMPUTERNAME) does not have enough space to perform a Windows Update. We have put off expanding the drive of this device because the datastore it is on has less than 15% free space left on it.<br>The below table contains information on the $VCServer datastores.<br><br><hr><br><br>" | Out-String

            Send-MailMessage -Priority High -From $From -SmtpServer $SmtpServer  -To $To  -Subject "ALERT: Low Disk Space $($VCServer) Datastore" -BodyAsHtml -Body "$MailBody" -Credential $MailCred
            Return $Results
            Disconnect-VIServer -Server * -Force -Confirm:$False
            Break

        } ElseIf ($Results) {

            Return $Results
            Write-Output "[*] The above output shows datastore information with low disk space"
            Disconnect-VIServer -Server * -Force -Confirm:$False
            Break

        } Else {
           
            Write-Output "No datastores with less than 15% disk free on $VIServer"

        }  # End If Else If Else

        Disconnect-VIServer -Server * -Force -Confirm:$False

    }  # End ForEach

}  # End Function Get-VMWareDatastoreSize

# Resize-VMsDiskSpace
Function Resize-VMsDiskSpace {
    [CmdletBinding(DefaultParameterSetName='Credential')]
        param(
            [ValidateNotNull()]
            [System.Management.Automation.PSCredential]
            [System.Management.Automation.Credential()]
            [Parameter(ParameterSetName="Credential")]
            $Credential = [System.Management.Automation.PSCredential]::Empty,

            [Parameter(
                Position=0,
                Mandatory=$True,
                ValueFromPipeline=$False,
                HelpMessage="Enter the number of Gigabytes to expand the disk space by. EXAMPLE: 25")]  # End Parameter
            [Int32]$SizeGB,

            [Parameter(
                ParameterSetName="BasicAuth",
                Position=1,
                Mandatory=$True,
                ValueFromPipeline=$False,
                HelpMessage="Enter the username to authenticate to the vSphere server with. EXAMPLE: mr.derp")]  # End Parameter
            [String]$Username,

            [Parameter(
                ParameterSetName="BasicAuth",
                Position=2,
                Mandatory=$True,
                ValueFromPipeline=$False,
                HelpMessage="Enter the password for the vSphere user account you defined. EXAMPLE: Password123!")]  # End Parameter
            [SecureString]$Password,

            [Parameter(
                Position=3,
                Mandatory=$False,
                ValueFromPipeline=$False,
                HelpMessage="Define the vSphere server to expand this disk on. EXAMPLE: vsphere.domain.com")]  # End Parameter
            [ValidateScript({Test-Connection -BufferSize 32 -Count 2 -ComputerName $_ -Quiet})]
            [String[]]$Server,

            [Parameter(
                Position=4,
                Mandatory=$False,
                ValueFromPipeline=$False
                #HelpMessage="Enter the security group(s) required to authenticate to the vSphere servers `nEXAMPLE: DOMAIN\vSphere Admins "
            )]  # End Parameter
            [String[]]$Group,

            [Parameter(
                ParameterSetName='BasicAuth',
                Mandatory=$False
            )]  # End Parameter
            [Switch][Bool]$UseBasicAuth
        )  # End param

    Write-Verbose "Verifying vSphere group membership"
    $CurrentUserId = [Security.Principal.WindowsIdentity]::GetCurrent()
    $GroupMembership = $CurrentUserId.Groups | ForEach-Object {

        $_.Translate([Security.Principal.NTAccount])

    }  # End ForEach-Object

    ForEach ($G in $Group) {

        If (!($GroupMembership.Value.Contains($G))) {

            Throw "[x] $($CurrentUserId.Name) does not have permissions to access vSphere"

        }  # End If

    }  # End ForEach

    If ((Get-PackageProvider -Name Nuget).Version -lt 2.8.5.201) {

        Try {

            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$False

        } Catch {

            Throw $Error

        }  # End Try Catch

    }  # End If

    Write-Verbose "Importing required modules"
    $ModuleNames = "VMware.VimAutomation.Core"
    If (!(Get-Module -ListAvailable -Name $ModuleNames)) {

        Instal-Module -Name $ModuleNames -Force -Confirm:$False

    }  # End If
    Import-Module -Name $ModuleNames -Force -ErrorAction Stop

    Write-Verbose "Connecting to $Server"    
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -ParticipateInCeip $False -DisplayDeprecationWarnings $False -Scope AllUsers -Confirm:$False | Out-Null

    Try {
       
        If ($PSCmdlet.ParameterSetName -eq 'Credential') {

            Write-Verbose "Connecting using -Credential"
            Connect-VIServer -Server $Server -Credential $Credential -Force -ErrorAction Stop | Out-Null

        } ElseIf ($UseBasicAuth.IsPresent) {

            Write-Verbose "Connecting using Basic Auth"
            $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)))
            Connect-VIServer -Server $Server -User $Username -Password $Password -Force -ErrorAction Stop | Out-Null

            Remove-Variable -Name Password

        } Else {

            Write-Verbose "Connecting using a Credential custom built"
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($Username, $Password)
            Connect-VIServer -Server $Server -Credential $Credential -Force -ErrorAction Stop | Out-Null

        }  # End If ElseIf Else

    } Catch {

        Throw "[x] Could not connect to vCenter $Server"

    }  # Try Catch

    $Domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
    $HardDisk = Get-HardDisk -VM "$env:COMPUTERNAME.$Domain"
    $HardDisk = $HardDisk | ForEach-Object { If ($_.Filename -notmatch "^(.*)_[0-9].vmdk") { $_ } } | Select-Object -First 1
    $Capacity = $HardDisk.CapacityGB


    Write-Verbose "Expanding the hard disk on $env:COMPUTERNAME"
    $HardDisk | Set-HardDisk -CapacityGB ($Capacity + $SizeGB) -Confirm:$False

    Write-Verbose "Updating the host storage cache to obtain the most up to date results"
    Update-HostStorageCache

    $ExistingSize = (Get-Partition -DriveLetter C).Size
    $MaxSize = (Get-PartitionSupportedSize -DriveLetter C).SizeMax
    If ($CurrentSize -ge $MaxSize) {

        Write-Output "[i] Disk is already at it's max available size"

    } Else {
   
        Resize-Partition -DriveLetter C -Size $MaxSize -Confirm:$False
        Get-Partition -DriveLetter C | Select-Object -Property DriveLetter,Size,Type,Offset,PartitionNumber

    }  # End If Else

    Disconnect-VIServer -Server * -Force -Confirm:$False

}  # End Resize-VMsDiskSpace


Get-VMWareDataStoreSize -Credential $Credential -Server $vCenterServer -Verbose
$LowStorage = Get-VMWareDataStoreSize -Credential $Credential -Verbose -SendEmailNotification -ErrorAction Continue
If ($Null -eq $LowStorage) {

    $MachineName = "$env:COMPUTERNAME.$((Get-CimInstance -ClassName Win32_ComputerSystem).Domain)"
    Resize-VMsDiskSpace -SizeGB 30 -Credential $Credential -Server $vCenterServer -ErrorAction Stop -Verbose

} Else {

    Write-Output "[x] Datastore $env:COMPUTERNAME is on has less than 15% disk space full"

}  # End If Else
