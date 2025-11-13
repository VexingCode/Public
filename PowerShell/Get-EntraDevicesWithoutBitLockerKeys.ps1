Function Get-EntraDevicesWithoutBitLockerKeys {
    param (
        [string]
        $outfile = "C:\Temp\DevicesWithoutBitlockerKeys.csv"
    )

    # Fetch BitLocker recovery keys
    $blKey = Get-MgBetaInformationProtectionBitlockerRecoveryKey -All -Property "id, createdDateTime, deviceId"

    # Fetch only Windows devices
    $dvc = Get-MgBetaDeviceManagementManagedDevice -All -Property "deviceName,id,azureADDeviceId" -Filter "operatingSystem eq 'Windows'" -ErrorAction Stop -ErrorVariable GraphError

    # Store BitLocker device IDs in a Hashtable for quick lookups
    $blKey_DeviceIds = @{}
    $blKey | ForEach-Object { $blKey_DeviceIds[$_.deviceId] = $true }

    # Filter devices that don't have a BitLocker Recovery Key
    $noBLKey = $dvc | Where-Object { -not $blKey_DeviceIds.ContainsKey($_.azureADDeviceId) }

    # Export results
    $noBLKey | Export-Csv -Path $outfile -NoTypeInformation

    Write-Output "The devices without a BitLocker Recovery Key are saved to: $outfile"
}
