<#
.SYNOPSIS
    Decrypts the OperatingSystem volume, as long as it has not been decrypted before.
.DESCRIPTION
    The script decrypts the volume marked "OperatingSystem". It will only trigger, if the registry
    key property is not present, or does not equal the revision number ($blPropertyValue) in this script.
.EXAMPLE
    PS C:\> Disable-BitlockerOSVolume.ps1
.INPUTS
    None, but edit the $blPropertyValue if necessary.
.OUTPUTS
    None
.NOTES
    Name:           Disable-BitlockerOSVolume.ps1
    Author:         Ahnamataeus Vex
    Version:        1.0.0
    Release Date:   2022-11-08
#>

# Set vars
$cosRegKey = 'HKLM:\SOFTWARE\CoS'
$blProperty = 'BL-Decrypted'
$blPropertyValue = '1'

Function Disable-BitlockerOSVolume {
    # Get the OperatingSystem Bitlocker Volume
    $BLV = Get-BitLockerVolume | Where-Object { $_.VolumeType -eq "OperatingSystem" }

    # Check if the volume is encrypted
    If ($BLV.ProtectionStatus -eq "On") {
        # Protection is on; disable it
        Disable-BitLocker -MountPoint $mountPoint | Out-Null
        Write-Output "Bitlocker found enabled on Operating System drive; decrypting."
    }
    Else {
        # Protection is off already
        Write-Output "Bitlocker not enabled on the Operating System drive."
    }
}

# Test if the $cosRegKey\Bitlocker registry key exists
If (!(Test-Path $cosRegKey\Bitlocker -ErrorAction SilentlyContinue)) {
    # Registry key does not exist; creating it
    New-Item -Path $cosRegKey\Bitlocker -Force | Out-Null

    # Disable Bitlocker, or ignore if already decrypted
    Disable-BitlockerOSVolume

    # Write the key showing its been decrypted
    New-ItemProperty $cosRegKey\Bitlocker -Name $blProperty -PropertyType String -Value $blPropertyValue -Force | Out-Null
    exit 0
}
Else {
    # Validate that the Bitlocker property actually exists with Get-ItemProperty; Get-ItemPropertyValue throws an irrepressible error
    If (Get-ItemProperty $cosRegKey\Bitlocker -Name $blProperty -ErrorAction SilentlyContinue) {
        # Bitlocker registry key exists; validate if its the same value as the script
        If ((Get-ItemPropertyValue $cosRegKey\Bitlocker -Name $blProperty) -eq $blPropertyValue) {
            # The values match; the drive has been decrypted already
            exit 0
        }
        Else {
            # The values do not match; decrypt the drive
            Disable-BitlockerOSVolume

            # Set the key to the new value
            Set-ItemProperty $cosRegKey\Bitlocker -Name $blProperty -Value $blPropertyValue -Force | Out-Null
            exit 0
        }
    }
    Else {
        # The Bitlocker path exists, but not the key; assume it has not been decrypted
        # Disable Bitlocker, or ignore if already decrypted
        Disable-BitlockerOSVolume

        # Write the key showing its been decrypted
        New-ItemProperty $cosRegKey\Bitlocker -Name $blProperty -PropertyType String -Value $blPropertyValue -Force | Out-Null
        exit 0
    }
}