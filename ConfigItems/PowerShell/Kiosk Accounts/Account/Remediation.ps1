# Remediation

# Set the vars
$KioskName = 'Kiosk'
$AutoLogonDomain = $env:COMPUTERNAME
$cntRegKey = 'HKLM:\SOFTWARE\CNT'
$CNTToolsDir = "$env:ProgramData\CNT\Tools"

Function Get-RandomPassword {
    # Generate a random length
    [int]$pwLength = Get-Random -Minimum 14 -Maximum 128
    # Set the number of Non-AlphaNumeric characters
    [int]$NumberOfNonAlphaNumericCharacters = 0
    Add-Type -AssemblyName 'System.Web'
    return [System.Web.Security.Membership]::GeneratePassword($pwLength, $NumberOfNonAlphaNumericCharacters)
}

# Check again to make sure the account isn't present
If (Get-LocalUser -Name $KioskName -ErrorAction SilentlyContinue) {
    # Account was found; return $true for compliant
    $true
}
Else {
    # Account was not found, proceed with the fix

    # Generate the password and secure it
    $Password = Get-RandomPassword

    # Create the local account
    New-LocalUser -Name $KioskName -Description "Account used for kiosk automatic login." -Password (ConvertTo-SecureString -String $Password -AsPlainText -Force) -AccountNeverExpires -PasswordNeverExpires -UserMayNotChangePassword | Out-Null

    # Validate the Autologon64.exe file is in the CNT\Tools directory; run it, if found
    If (!(Test-Path $CNTToolsDir\Autologon64.exe)) {
        # Autologon64.exe was not found; exit 2 (ERROR_FILE_NOT_FOUND)
        exit 2
    }
    Else {
        # Run the Autologon64.exe to configure the autologon
        Start-Process -FilePath "$CNTToolsDir\Autologon64.exe" -ArgumentList "/AcceptEula $KioskName $AutoLogonDomain $Password"
    }

    # Test if the $cntRegKey\AutoLogon exists; create it, if not
    If (!(Test-Path $cntRegKey\Autologon -ErrorAction SilentlyContinue)) {
        New-Item -Path $cntRegKey\Autologon -Force | Out-Null
    }

    # Set keys to indicate that the CI fixed the account
    New-ItemProperty $cntRegKey\Autologon -Name AL-CIAcctFix -PropertyType String -Value "True" -Force | Out-Null
    New-ItemProperty $cntRegKey\Autologon -Name AL-CIAcctFixTimeStamp -PropertyType String -Value (Get-Date) -Force | Out-Null

    # Clear the password variables (best to be sure, m'kay?)
    Clear-Variable -Name "password"
}