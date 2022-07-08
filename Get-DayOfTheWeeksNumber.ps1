<#
.SYNOPSIS
This cmdlet is used to get the day of the month that a day occurs by definig the day and which week it is in


.DESCRIPTION
Get the day of the month that a day occurs on based on which week of the month it occurs in


.PARAMETER DayOfWeek
Define which day of the week you are looking to discover

.PARAMETER WhichWeek
Define which week of the month to use in discovering the month day number a day name occurs in

.PARAMETER Month
Specify any month of any year you want to return this info on

.PARAMETER Year
Specify any year you want to return this info on


.EXAMPLE
Get-DayOfTheWeeksNumber -DayOfWeek "Tuesday" -WhichWeek 2
# Get the second Tuesday of the months date

.EXAMPLE
Get-DayOfTheWeeksNumber "Wednesday" 3
# Get the third Wednesday of the months date

.EXAMPLE
Get-DayOfTheWeeksNumber -DayOfWeek "Tuesday" -WhichWeek 2 -Month January -Year 200
# Get the second Tuesday of the month in January year 2000


.NOTES
Author: Robert H. Osborne
Alias: tobor
Contact: rosborne@osbornepro.com


.INPUTS
None


.OUTPUTS
System.ValueType DateTime


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
Function Get-DayOfTheWeeksNumber {
    [CmdletBinding()]
        param(
            [Parameter(
                Position=0,
                Mandatory=$True,
                ValueFromPipeline=$False,
                HelpMessage="Define the day of the week you want: `nEXAMPLE: Tuesday")]  # End Parameter
            [ValidateSet('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')]
            [String]$DayOfWeek,

            [Parameter(
                Position=1,
                Mandatory=$True,
                ValueFromPipeline=$False,
                HelpMessage="Identify  which week of the month you want: `nEXAMPLE: 2")]  # End Parameter
            [ValidateRange(1,6)]
            [Int32]$WhichWeek,

            [Parameter(
                Position=2,
                Mandatory=$False,
                ValueFromPipeline=$False,
                HelpMessage="Identify  which week of the month you want: `nEXAMPLE: 2")]  # End Parameter
            [ValidateSet('January','February','March','April','May','June','July','August','September','October','November','December')]
            [String]$Month = $((Get-Culture).DateTimeFormat.GetMonthName((Get-Date).Month)),

            [Parameter(
                Position=3,
                Mandatory=$False,
                ValueFromPipeline=$False,
                HelpMessage="Identify  which week of the month you want: `nEXAMPLE: 2")]  # End Parameter
            [ValidateScript({$_ -match '(\d\d\d\d)'})]
            [Int32]$Year = (Get-Date).Year
        )  # End param

    $Today = Get-Date -Date "$Month $Year"
    $Subtract = $Today.Day - 1
    [datetime]$MonthStart = $Today.AddDays(-$Subtract)
    While ($MonthStart.DayOfWeek -ne $DayOfWeek) {

        $MonthStart = $MonthStart.AddDays(1)

    }  # End While

    Return $MonthStart.AddDays(7*($WhichWeek - 1))

}  # End Get-DayOfTheWeeksNumber
