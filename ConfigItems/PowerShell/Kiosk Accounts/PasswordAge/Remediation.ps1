# Remediation

# Set vars
$KioskName = 'CNTKiosk'
$AutoLogonDomain = $env:COMPUTERNAME
$CNTRegKey = 'HKLM:\SOFTWARE\CNT'
$CNTToolsDir = "$env:ProgramData\CNT\Tools"

Function Get-RandomPassword {
    # Generate a random length
    [int]$pwLength = Get-Random -Minimum 14 -Maximum 128
    # Set the number of Non-AlphaNumeric characters
    [int]$NumberOfNonAlphaNumericCharacters = 0
    Add-Type -AssemblyName 'System.Web'
    return [System.Web.Security.Membership]::GeneratePassword($pwLength, $NumberOfNonAlphaNumericCharacters)
}

# Generate the password and secure it
$Password = Get-RandomPassword

# Validate the Autologon64.exe file is in the CNT\Tools directory; run it, if found
If (!(Test-Path $CNTToolsDir\Autologon64.exe)) {
    # Autologon64.exe was not found; exit 2 (ERROR_FILE_NOT_FOUND)
    exit 2
}
Else {
    # Detect if the account was found
    If (Get-LocalUser -Name $KioskName -ErrorAction SilentlyContinue) {
        # Account was found; reset the password
        Set-LocalUser -Name $KioskName -Password (ConvertTo-SecureString -String $Password -AsPlainText -Force) -AccountNeverExpires -PasswordNeverExpires $true -UserMayChangePassword $false | Out-Null

        # Run the Autologon64.exe to configure the autologon
        Start-Process -FilePath "$CNTToolsDir\Autologon64.exe" -ArgumentList "/AcceptEula $KioskName $AutoLogonDomain $Password"

        # Test if the $CNTRegKey\AutoLogon exists; create it, if not
        If (!(Test-Path $CNTRegKey\Autologon -ErrorAction SilentlyContinue)) {
            New-Item -Path $CNTRegKey\Autologon -Force | Out-Null
        }

        # Set key to indicate when the CI cycled the password last
        New-ItemProperty $CNTRegKey\Autologon -Name AL-CIPWCycleTimeStamp -PropertyType String -Value (Get-Date) -Force | Out-Null

        # Clear the password variables (best to be sure, m'kay?)
        Clear-Variable -Name "password"
    }
    Else {
        # Account was not found
        exit 1
    }
}