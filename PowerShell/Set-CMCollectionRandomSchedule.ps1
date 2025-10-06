Function Set-CMCollectionRefreshMode {
    [CmdletBinding(DefaultParameterSetName = 'RandomSchedule')]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$CollectionIDs,

        [Parameter(ParameterSetName = 'RandomSchedule')]
        [int]$IntervalDays = 3,

        [Parameter(ParameterSetName = 'DisableAll', Mandatory = $true)]
        [switch]$DisableAll,

        [Parameter(ParameterSetName = 'EnableIncremental', Mandatory = $true)]
        [switch]$EnableIncremental
    )

    ForEach ($CollectionID in $CollectionIDs) {
        $collection = Get-CMCollection -Id $CollectionID
        If (-not $collection) {
            Write-Warning "CollectionID '$CollectionID' not found."
            continue
        }

        switch ($PSCmdlet.ParameterSetName) {
            'DisableAll' {
                Set-CMCollection -CollectionId $CollectionID -RefreshType Manual
                Write-Output "Disabled all updates for '$($collection.Name)'"
            }

            'EnableIncremental' {
                Set-CMCollection -CollectionId $CollectionID -RefreshType Continuous
                Write-Output "Enabled incremental updates for '$($collection.Name)'"
            }

            'RandomSchedule' {
                $randomHour = Get-Random -Minimum 0 -Maximum 24
                $randomMinute = Get-Random -Minimum 0 -Maximum 60
                $startTime = [datetime]::Today.AddHours($randomHour).AddMinutes($randomMinute)

                $schedule = New-CMSchedule -RecurInterval Days -RecurCount $IntervalDays -Start $startTime

                Set-CMCollection -CollectionId $CollectionID -RefreshType Periodic -RefreshSchedule $schedule
                Write-Output "Set randomized full refresh for '$($collection.Name)' every $IntervalDays day(s) at $($startTime.ToShortTimeString())"
            }
        }
    }
}