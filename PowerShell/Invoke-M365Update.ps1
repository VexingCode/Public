param (
    [ValidateSet('Enable', 'Disable')]
    [string]
    $ConfigMgrMgmt = 'Enable',
    [bool]
    $InitiateUpdate = $false
)

$regKey = 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration'

$oMCOMProperty = 'OfficeMgmtCOM'
$cdnURLProperty = 'CDNBaseUrl'
$uChProperty = 'UpdateChannel'
$uUrlProperty = 'UpdateUrl'

# Set comMgmtValue based on ConfigMgrMgmt
$comMgmtValue = if ($ConfigMgrMgmt -eq 'Enable') { 'True' } else { 'False' }

# Get the CDNBaseUrl value
$cdnURLValue = (Get-ItemProperty -Path $regKey -Name $cdnURLProperty).$cdnURLProperty

# Update UpdateChannel if it exists and is not equal to CDNBaseUrl
if (Test-Path $regKey) {
    if (Get-ItemProperty -Path $regKey -Name $uChProperty -ErrorAction SilentlyContinue) {
        $uChValue = (Get-ItemProperty -Path $regKey -Name $uChProperty).$uChProperty
        if ($uChValue -ne $cdnURLValue) {
            Set-ItemProperty -Path $regKey -Name $uChProperty -Value $cdnURLValue
            Write-Output "UpdateChannel exists and was set to $cdnURLValue."
        } else {
            Write-Output "UpdateChannel exists and is already set to $cdnURLValue."
        }
    } else {
        Write-Output "UpdateChannel does not exist."
    }
}

# Update UpdateUrl if it exists and is not equal to CDNBaseUrl
if (Test-Path $regKey) {
    if (Get-ItemProperty -Path $regKey -Name $uUrlProperty -ErrorAction SilentlyContinue) {
        $uUrlValue = (Get-ItemProperty -Path $regKey -Name $uUrlProperty).$uUrlProperty
        if ($uUrlValue -ne $cdnURLValue) {
            Set-ItemProperty -Path $regKey -Name $uUrlProperty -Value $cdnURLValue
            Write-Output "UpdateUrl exists and was set to $cdnURLValue."
        } else {
            Write-Output "UpdateUrl exists and is already set to $cdnURLValue."
        }
    } else {
        Write-Output "UpdateUrl does not exist."
    }
}

# Check if OfficeMgmtCOM exists and set it to the specified value
if (Test-Path $regKey) {
    if (Get-ItemProperty -Path $regKey -Name $oMCOMProperty -ErrorAction SilentlyContinue) {
        Set-ItemProperty -Path $regKey -Name $oMCOMProperty -Value $comMgmtValue
        Write-Output "OfficeMgmtCOM exists and was set to $comMgmtValue."
    } else {
        Write-Output "OfficeMgmtCOM does not exist."
    }
}

# Run the specified task if InitiateUpdate is true
if ($InitiateUpdate) {
    $taskPath = "\Microsoft\Office\"
    $taskName = "Office Automatic Updates 2.0."
    Start-ScheduledTask -TaskPath $taskPath -TaskName $taskName
    Write-Output "Scheduled task, Office Automatic Updates 2.0, was initiated."
} else {
    Write-Output "Scheduled task, Office Automatic Updates 2.0, was not initiated."
}