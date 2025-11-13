try
{
    Write-Host "Pulling Physical Network Adapters Power Management Settings"
    $adapters = Get-NetAdapter -Physical -ErrorAction SilentlyContinue
    $adapters
    $adapterPowerManagement = $adapters | Get-NetAdapterPowerManagement -ErrorAction SilentlyContinue
    $adapterPowerManagement
    if($adapters -and $adapterPowerManagement)
    {
        foreach ($adapter in $adapterPowerManagement)
        {
            Write-Host "Turning off AllowComputerToTurnOffDevice for Network Adapter: $($adapter.InterfaceDescription)"
            $adapter.AllowComputerToTurnOffDevice = 'Disabled'
            $adapter | Set-NetAdapterPowerManagement -ErrorAction Stop
        }
    }
}
catch
{
    Write-Host "Error pulling adapter information. Exception: $($_.Exception.Message)"
}