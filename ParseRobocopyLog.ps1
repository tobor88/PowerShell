$Path = Read-Host -Prompt "Enter the directory path location contianing your robocopy logs `nNOTE: This filters for all TXT files in the directory you specify`n`nEXAMPLE: C:\Temp\Logs"
$Files = Get-ChildItem -Path $Path -Filter "*.txt" -File

$Results = @()
$ErrorFileResults = @()

ForEach ($File in $Files.FullName) {

    $Started = ((Select-String -Path $File -Pattern " Started : " -Context 14,7 | Out-String).Trim()).Split(">")
    For ($i = 0; $i -le $Started.Count; $i++) {

        $Instance = ((Select-String -Path $File -Pattern " Started : " -Context 14,7 | Out-String).Trim()).Split(">")[$i]
        If ($Instance -like "*Total    Copied   Skipped  Mismatch    FAILED    Extras*") {

            $Evens = 0

            [array]$Start = (Select-String -Path $File -Pattern " Started : " | Out-String).Trim().Split([Environment]::NewLine)
            For ($n = 0; $n -le $(($Start.Count + 1) / 2); $n++) {

                $Begin = ((Select-String -Path $File -Pattern " Started : " | Out-String).Trim().Split([Environment]::NewLine)[$Evens]).Split(" ")
                $S = Get-Date -Date "$($Begin[-6]) $($Begin[-5]) $($Begin[-4]) $($Begin[-3]) $($Begin[-2]) $($Begin[-1])" -Format 'MM/dd/yyyy hh:mm:ss'
                $Source = ((Select-String -Path $File -Pattern "Source : " | Out-String).Trim().Split([Environment]::NewLine)[$Evens]).Split(":")[-1].Trim()
                $Dest = ((Select-String -Path $File -Pattern "Dest : " | Out-String).Trim().Split([Environment]::NewLine)[$Evens]).Split(":")[-1].Trim()
                $FileCounts = (Select-String -Path $File -Pattern "Files : " | Out-String).Trim().Split([Environment]::NewLine)[$Evens]
                $Total = ($FileCounts.Replace("      ","|").Split("|")[1]).Trim()
                $Copied = ($FileCounts.Replace("      ","|").Split("|")[2]).Trim()
                $Skipped = ($FileCounts.Replace("      ","|").Split("|")[3]).Trim()
                $Mismatch = ($FileCounts.Replace("      ","|").Split("|")[4]).Trim()
                $Failed = ($FileCounts.Replace("      ","|").Split("|")[5]).Trim()
                $Extras = ($FileCounts.Replace("      ","|").Split("|")[6]).Trim()
                $DestinationCount = [Int]$Copied + [Int]$Skipped
                $ByteInfo = (Select-String -Path $File -Pattern "Bytes : " | Out-String).Trim().Split([Environment]::NewLine)[$Evens]
                $TotalBytes = $ByteInfo.Replace("   ","|").Split("|")[2].Trim()
                $CopiedBytes = $ByteInfo.Replace("   ","|").Split("|")[3].Trim()
                $SkippedBytes = $ByteInfo.Replace("   ","|").Split("|")[4].Trim()
                $DestBytes = [Int]$CopiedBytes + [Int]$SkippedBytes

                $Results += New-Object -TypeName PSCustomObject -Property @{
        
                    Started=$($S);
                    Source=$($Source);
                    TotalSourceFiles=$Total;
                    Destination=$($Dest);
                    TotalDestFiles=$($DestinationCount);
                    TotalBytes=$TotalBytes;
                    TotalDestBytes=$DestBytes;
                    CopiedBytes=$CopiedBytes;
                    SkippedBytes=$SkippedBytes;
                    LogFile=$($File);

                }  # End New-Object -Property

                $Evens = $Evens + 2
          
            }  # End For

        }  # End If
    
    }  # End For

    $Results | Format-Table -AutoSize

    $Errors = (Select-String -Pattern "ERROR (\d)[0,2]" -Path $File | Out-String).Trim().Split([Environment]::NewLine) # \((0x8(.*){5,20})\)" -Path $File
    ForEach ($Err in $Errors) {

        If ($Err -like "*ERROR*") {

            $ErrorCode = $Err.Split("(").Split(")")[1]
            $FilePath = $Err.Split(")")[-1].Substring(13).Trim()
            Switch ($ErrorCode) {

                "0x00000000" { $ErrorMessage = "The operation completed successfully" }
                "0x00000002" { $ErrorMessage = "File not found error" }
                "0x00000003" { $ErrorMessage = "File not found errors" }
                "0x00000005" { $ErrorMessage = "Access denied errors" }
                "0x00000006" { $ErrorMessage = "Invalid handle errors" }
                "0x00000020" { $ErrorMessage = "The process cannot access the file because it is being used by another process" }
                "0x00000035" { $ErrorMessage = "Network path not found errors" }
                "0x00000040" { $ErrorMessage = "The specified network name is no longer available" }
                "0x00000070" { $ErrorMessage = "Disk full errors" }
                "0x00000079" { $ErrorMessage = "Semaphore timeout errors" }
                "0x00000033" { $ErrorMessage = "Network path errors" }
                "0x0000003B" { $ErrorMessage = "An unexpected network error occurred" }
                "0x0000003A" { $ErrorMessage = "NTFS security errors" }
                "0x0000054F" { $ErrorMessage = "Internal errors" }

            }  # End Switch

            $ErrorFileResults += New-Object -TypeName PSCustomObject -Property @{
                ErrorCode=$ErrorCode;
                ErrorMessage=$ErrorMessage;
                FilePath=$FilePath;
            }  # End New-Object -Property

        }  # End If

    }  # End ForEach

    $ErrorFileResults

}  # End ForEach
