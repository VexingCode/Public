<#
.SYNOPSIS
    Validate local user password compliance.
.DESCRIPTION
    Checks a Windows local user account for the date of the last password change and compares it to a fixed date. 
    Designed to be embedded in other scripts.
.PARAMETER LocalUser
    Specify the name of the local user account you wish to target.
.PARAMETER DaysPassed
    Specify the amount of days till the password is "expired."
.EXAMPLE
    C:\Windows\System32> Test-LocaluserPasswordExpiration -LocalUser "TestAcct" -DaysPassed "90"

    This example will return $true if the password is older than 90 days. If not, it will return
.OUTPUTS
    "Compliant" - The password falls within the days specified, so it is Compliant.
    "NonCompliant" - The password does not fall within the days specified, so it is NonCompliant.
.NOTES
    Name:           Test-LocalUserPasswordExpiration
    Author:         Jason Kuhn
    Contributor:    Ahnamataeus Vex
    Version:        1.0.0
    Release Date:   2022-07-20
    Updated:
        Version 1.0.1: 2022-07-20
            Built out as a function
            Change the boolean to specified values due to the positive/negative relation ($true = NonCompliant); reduces confusion
#>

Function Test-LocalUserPasswordExpiration {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $LocalUser,
        [Parameter()]
        [string]
        $DaysPassed
    )

    # Get the current date, and subtract the DaysPassed to find the NonCompliance age
    $pwNonComplianceAge = (Get-Date).AddDays(-$DaysPassed)
    # Get the date the password was last set on the specified local user account
    $pwSetDate = Get-LocalUser -Name $LocalUser | Select-Object -ExpandProperty PasswordLastSet

    If ($pwSetDate -lt $pwNonComplianceAge) {
        # The password is older than the specified timeframe; return "NonCompliant"
        return "NonCompliant"
    }
    Else {
        # The password is not older than the specified timeframe; return $false for compliance
        return "Compliant"
    }
}