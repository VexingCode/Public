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
        Updated:
            Version 1.0.1: 2022-11-09
                - Separated the Disable-BitlockerOSVolume to its own function so it could be called
                - Added the creation/detection of a custom regkey to indicate it had been run (or that it ran 
                and the drive was already decrypted)
                - Added a Try/Catch block on the Disable-Bitlocker step to grab it if it errs out (previously had
                a typo causing one...)
#>

# Set vars
$cntRegKey = 'HKLM:\SOFTWARE\CNT'
$blProperty = 'BL-Decrypted'
$blPropertyValue = '1'

Function Disable-BitlockerOSVolume {
    # Get the OperatingSystem Bitlocker Volume
    $BLV = Get-BitLockerVolume | Where-Object { $_.VolumeType -eq "OperatingSystem" }

    # Check if the volume is encrypted
    If ($BLV.ProtectionStatus -eq "On") {
        # Protection is on; disable it
        Try {
            Disable-BitLocker -MountPoint $BLV.MountPoint -ErrorAction Stop | Out-Null
        }
        Catch {
            Write-Warning $Error[0].Exception.Message
            exit 1
        }
        Write-Output "Bitlocker found enabled on Operating System drive; decrypting."
    }
    Else {
        # Protection is off already
        Write-Output "Bitlocker not enabled on the Operating System drive."
    }
}

# Test if the $cntRegKey\Bitlocker registry key exists
If (!(Test-Path $cntRegKey\Bitlocker -ErrorAction SilentlyContinue -Verbose)) {
    # Registry key does not exist; creating it
    New-Item -Path $cntRegKey\Bitlocker -Force | Out-Null

    # Disable Bitlocker, or ignore if already decrypted
    Disable-BitlockerOSVolume

    # Write the key showing its been decrypted
    New-ItemProperty $cntRegKey\Bitlocker -Name $blProperty -PropertyType String -Value $blPropertyValue -Force | Out-Null
    exit 0
}
Else {
    # Validate that the Bitlocker property actually exists with Get-ItemProperty; Get-ItemPropertyValue throws an irrepressible error
    If (Get-ItemProperty $cntRegKey\Bitlocker -Name $blProperty -ErrorAction SilentlyContinue -Verbose) {
        # Bitlocker registry key exists; validate if its the same value as the script
        If ((Get-ItemPropertyValue $cntRegKey\Bitlocker -Name $blProperty) -eq $blPropertyValue) {
            # The values match; the drive has been decrypted already
            Write-Output "The devices has already been decrypted."
            exit 0
        }
        Else {
            # The values do not match; decrypt the drive
            Disable-BitlockerOSVolume

            # Set the key to the new value
            Set-ItemProperty $cntRegKey\Bitlocker -Name $blProperty -Value $blPropertyValue -Force | Out-Null
            exit 0
        }
    }
    Else {
        # The Bitlocker path exists, but not the key; assume it has not been decrypted
        # Disable Bitlocker, or ignore if already decrypted
        Disable-BitlockerOSVolume

        # Write the key showing its been decrypted
        New-ItemProperty $cntRegKey\Bitlocker -Name $blProperty -PropertyType String -Value $blPropertyValue -Force | Out-Null
        exit 0
    }
}