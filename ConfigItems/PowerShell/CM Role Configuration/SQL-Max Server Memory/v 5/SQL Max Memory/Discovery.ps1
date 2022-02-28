# If you have multiple instances, set to the specific instance:
# $ServerInstance = "sql01\SQLInstance01"

### CONFIGURE THESE ###
$ServerInstance = "127.0.0.1"
$OsReservedMemory = 2048
$PercentMemoryToUse = .8
### CONFIGURE THESE ###

[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
$srv = New-Object Microsoft.SQLServer.Management.Smo.Server($ServerInstance)

$mem = Get-WMIObject -class Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum

$memtotal = $mem.Sum / 1MB

If ($memtotal -gt $OsReservedMemory)
{
    $SqlMaxMemory = ($memtotal-$min_os_mem)*$PercentMemoryToUse
}
else
{
    $SqlMaxMemory = 512
}

If ($SqlMaxMemory -lt 512)
{
    $SqlMaxMemory = 512
}

#Write-Host $sql_max_mem

If ($srv.Configuration.MaxServerMemory.ConfigValue -eq $SqlMaxMemory)
{
    #Write-Host Correctly configured
    Return $true
}
Else
{
    #Write-Host Fail to meet max mem
    #Write-Host $srv.Configuration.MaxServerMemory.ConfigValue
    Return $false
}
