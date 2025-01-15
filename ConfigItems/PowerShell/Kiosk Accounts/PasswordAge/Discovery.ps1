# Discovery

# Function to validate if the password is noncompliant
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

    If (Get-LocalUser -Name $LocalUser -ErrorAction SilentlyContinue) {
        # Get the date the password was last set on the specified local user account
        $pwSetDate = Get-LocalUser -Name $LocalUser -ErrorAction SilentlyContinue | Select-Object -ExpandProperty PasswordLastSet

        If ($pwSetDate -lt $pwNonComplianceAge) {
            # The password is older than the specified timeframe; return "NonCompliant"
            return "NonCompliant"
        }
        Else {
            # The password is not older than the specified timeframe; return $false for compliance
            return "Compliant"
        }
    }
    Else {
        # The account does not exist, so we assume compliant; the other CI will remediate and set the password anew
        return "Compliant"
    }
}

Test-LocalUserPasswordExpiration -LocalUser "Kiosk" -DaysPassed 90