Function Set-CMCollectionRandomSchedule {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$CollectionIDs,

        [Parameter(Mandatory = $true)]
        [int]$IntervalDays
    )

    ForEach ($CollectionID in $CollectionIDs) {
        $collection = Get-CMDeviceCollection -CollectionId $CollectionID
        If (-not $collection) {
            Write-Warning "CollectionID '$CollectionID' not found."
            continue
        }

        # Disable incremental updates
        $collection.RefreshType = 2  # 2 = Full Update on schedule only
        $collection.Put()

        # Generate randomized schedule time
        $randomHour = Get-Random -Minimum 0 -Maximum 24
        $randomMinute = Get-Random -Minimum 0 -Maximum 60
        $startTime = [datetime]::Today.AddHours($randomHour).AddMinutes($randomMinute)

        # Create a new schedule token
        $schedule = New-CMSchedule -RecurInterval Days -RecurCount $IntervalDays -Start $startTime

        # Apply the schedule
        Set-CMDeviceCollection -CollectionId $CollectionID -RefreshSchedule $schedule

        Write-Output "Updated '$($collection.Name)' with full update every $IntervalDays day(s) at $($startTime.ToShortTimeString())"
    }
}