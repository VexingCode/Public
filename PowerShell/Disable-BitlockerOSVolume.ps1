# Get the OperatingSystem Bitlocker Volume
$BLV = Get-BitLockerVolume | Where-Object { $_.VolumeType -eq "OperatingSystem" }

# Check if the volume is encrypted
If ($BLV.ProtectionStatus -eq "On") {
    # Protection is on; disable it
    Disable-BitLocker -MountPoint $mountPoint | Out-Null
    Write-Output "Bitlocker found enabled on Operating System drive; decrypting."
    exit 0
}
Else {
    # Protection is off already
    Write-Output "Bitlocker not enabled on the Operating System drive."
    exit 0
}