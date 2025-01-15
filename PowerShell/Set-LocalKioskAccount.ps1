<#
.SYNOPSIS
    Create or repair the Kiosk account for Autologon.
.DESCRIPTION
    Intended to be used manually or as an app in ConfigMgr. Creates or repairs the kiosk account
    used for autologon. Steps to remove the autologon and account are purposefully not coded out.
.PARAMETER NewKiosk
    Specifies that this is a new Kiosk setup.
.PARAMETER DaysPassed
    Specifies that this is a repair Kiosk setup.
.PARAMETER KioskName
    What is the name of the kiosk account you want built.
.EXAMPLE
    C:\Windows\System32> Set-LocalKioskAccount -NewKiosk -KioskName "TestAcct"

    C:\Windows\System32> Set-LocalKioskAccount -RepairKiosk -KioskName "TestAcct"
.OUTPUTS
    Regkeys are written under HKLM:\SOFTWARE\CNT\Autologon
.NOTES
    Name:           Set-LocalKioskAccount.ps1
    Author:         Ahnamataeus Vex
    Version:        1.0.0
    Release Date:   2022.07.20
        Updated:
            Version 1.0.1: 2022.07.25
                Added the registry key to ForceAutoLogon
#>

<# Uncomment if using as a CM app
[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $New,
    [Parameter()]
    [switch]
    $Repair
)
#>

Function Set-LocalKioskAccount {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,ParameterSetName="NewKioskSet",Position=0)]
        [switch]
        $NewKiosk,
        [Parameter(Mandatory=$true,ParameterSetName="RepairKioskSet",Position=0)]
        [switch]
        $RepairKiosk,
        [Parameter(Mandatory=$true,Position=1)]
        [string]
        $KioskName
    )

    # Set vars
    $AutoLogonDomain = $env:COMPUTERNAME
    $CNTRegKey = 'HKLM:\SOFTWARE\CNT'
    $alProperties = 'AL-Installed','AL-KioskName','AL-Timestamp'
    $winlogonRegKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
    $winlogonProperties = 'DefaultDomainName','DefaultUserName'
    $CNTToolsDir = "$env:ProgramData\CNT\Tools"

    # Check for the existence of the CNT\Tools directory, and create it if missing
    If (!(Test-Path $CNTToolsDir)) {
        New-Item $CNTToolsDir -ItemType Directory
    }

    # Validate the Autologon64.exe file is in the CNT\Tools directory; copy it over if its not
    If (!(Test-Path $CNTToolsDir\Autologon64.exe)) {
        Copy-Item -Path "$PSScriptRoot\Autologon64.exe" -Destination $CNTToolsDir
    }

    # Function to generate an obfuscated password with the a random length between 14 and 128, and 0 non-alphanumeric characters
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

    # New kiosk specified
    If ($NewKiosk) {
        # Validate if the account exists
        If (Get-LocalUser -Name $KioskName -ErrorAction SilentlyContinue) {
            # Account was found
            # Reset the password
            Set-LocalUser -Name $KioskName -Password (ConvertTo-SecureString -String $Password -AsPlainText -Force) -AccountNeverExpires -PasswordNeverExpires $true -UserMayChangePassword $false | Out-Null
        }
        Else {
            # Account was not found
            New-LocalUser -Name $KioskName -Description "Account used for kiosk automatic login." -Password (ConvertTo-SecureString -String $Password -AsPlainText -Force) -AccountNeverExpires -PasswordNeverExpires -UserMayNotChangePassword | Out-Null
        }

        # Run the Autologon .exe
        Start-Process -FilePath "$CNTToolsDir\Autologon64.exe" -ArgumentList "/AcceptEula $KioskName $AutoLogonDomain $Password"

        # Test for the ForceAutoLogon property; create/set it, if not
        If (Get-ItemProperty -Path $winlogonRegKey -Name ForceAutoLogon -ErrorAction SilentlyContinue) {
            # Property found; set the property value to 1
            Set-ItemProperty -Path $winlogonRegKey -Name ForceAutoLogon -Value 1
        }
        Else {
            # Property not found; create it and set the value to 1
            New-ItemProperty -Path $winlogonRegKey -Name ForceAutoLogon -PropertyType DWord -Value 1
        }

        # Test if the $CNTRegKey\AutoLogon exists; create it, if not
        If (!(Test-Path $CNTRegKey\Autologon -ErrorAction SilentlyContinue)) {
            New-Item -Path $CNTRegKey\Autologon -Force | Out-Null
        }

        # Create the Autologon keys
        New-ItemProperty $CNTRegKey\Autologon -Name AL-Installed -PropertyType String -Value "True" -Force | Out-Null
        New-ItemProperty $CNTRegKey\Autologon -Name AL-KioskName -PropertyType String -Value $KioskName -Force | Out-Null
        New-ItemProperty $CNTRegKey\Autologon -Name AL-Timestamp -PropertyType String -Value (Get-Date) -Force | Out-Null

        # Clear the password variables
        Clear-Variable -Name "password"

    }
    # Repair kiosk specified
    ElseIf ($RepairKiosk) {
        
        ######################
        ## Pre-Repair Steps ##
        ######################

        # Validate the Autologon64.exe file is in the CNT\Tools directory; delete\recopy it if it is, copy it over if its not
        If (Test-Path $CNTToolsDir\Autologon64.exe) {
            Remove-Item -Path "$CNTToolsDir\Autologon64.exe" -Force
            Copy-Item -Path "$PSScriptRoot\Autologon64.exe" -Destination $CNTToolsDir
        }
        Else {
            Copy-Item -Path "$PSScriptRoot\Autologon64.exe" -Destination $CNTToolsDir
        }

        # Nuke the Default* property values, if not empty
        ForEach ($property in $winlogonProperties) {
            If (Get-ItemPropertyValue -Path $winlogonRegKey -Name $property -ErrorAction SilentlyContinue) { 
                Clear-ItemProperty -Path $winlogonRegKey -Name $property
            }
        }

        # Nuke the AL- property values
        ForEach ($alProperty in $alProperties) {
            If (Get-ItemPropertyValue -Path $CNTRegKey\Autologon -Name $alProperty -ErrorAction SilentlyContinue) { 
                Clear-ItemProperty -Path $CNTRegKey\Autologon -Name $alProperty
            }
        }

        # Set the AutoAdminLogon to 0
        If ((Get-ItemPropertyValue -Path $winlogonRegKey -Name AutoAdminLogon) -ne 0) {
            Set-ItemProperty -Path $winlogonRegKey -Name AutoAdminLogon -Value 0
        }

        # Set the ForceAutoLogon to 0
        If ((Get-ItemPropertyValue -Path $winlogonRegKey -Name ForceAutoLogon) -ne 0) {
            Set-ItemProperty -Path $winlogonRegKey -Name ForceAutoLogon -Value 0
        }

        ##################
        ## Repair Steps ##
        ##################

        # Validate that the account actually exists
        If (Get-LocalUser -Name $KioskName -ErrorAction SilentlyContinue) {
            # Account was found
            # Reset the password
            Set-LocalUser -Name $KioskName -Password (ConvertTo-SecureString -String $Password -AsPlainText -Force) -AccountNeverExpires -PasswordNeverExpires $true -UserMayChangePassword $false | Out-Null
        }
        Else {
            # Account was not found
            New-LocalUser -Name $KioskName -Description "Account used for kiosk automatic login." -Password (ConvertTo-SecureString -String $Password -AsPlainText -Force) -AccountNeverExpires -PasswordNeverExpires -UserMayNotChangePassword | Out-Null
        }

        # Run the Autologon .exe
        Start-Process -FilePath "$CNTToolsDir\Autologon64.exe" -ArgumentList "/AcceptEula $KioskName $AutoLogonDomain $Password"

        # Test for the ForceAutoLogon property; create/set it, if not
        If (Get-ItemProperty -Path $winlogonRegKey -Name ForceAutoLogon -ErrorAction SilentlyContinue) {
            # Property found; set the property value to 1
            Set-ItemProperty -Path $winlogonRegKey -Name ForceAutoLogon -Value 1
        }
        Else {
            # Property not found; create it and set the value to 1
            New-ItemProperty -Path $winlogonRegKey -Name ForceAutoLogon -PropertyType DWord -Value 1
        }

        # Test if the $CNTRegKey\AutoLogon exists; create it, if not
        If (!(Test-Path $CNTRegKey\Autologon -ErrorAction SilentlyContinue)) {
            New-Item -Path $CNTRegKey\Autologon -Force | Out-Null
        }

        # Create the Autologon keys
        New-ItemProperty $CNTRegKey\Autologon -Name AL-Installed -PropertyType String -Value "True" -Force | Out-Null
        New-ItemProperty $CNTRegKey\Autologon -Name AL-KioskName -PropertyType String -Value $KioskName -Force | Out-Null
        New-ItemProperty $CNTRegKey\Autologon -Name AL-Timestamp -PropertyType String -Value (Get-Date) -Force | Out-Null

        # Clear the password variables
        Clear-Variable -Name "password"

    }

    # Clear the password variables (best to be sure, m'kay?)
    Clear-Variable -Name "password"

}

<# Uncomment if using as a CM app
If ($New) {
    Set-LocalKioskAccount -NewKiosk -KioskName "CNTKiosk"
}
ElseIf ($Repair) {
    Set-LocalKioskAccount -RepairKiosk -KioskName "CNTKiosk"
}
#>