# Detection and Remediation for a ConfigMgr Configuration Item
# Can be revamped later for an Intune Proactive Remediation

# Detection Method; run as user credentials

$TeamsExePath = [System.IO.Path]::Combine($env:LOCALAPPDATA, 'Microsoft', 'Teams', 'Current', 'Teams.exe')

If (Test-Path -Path $TeamsExePath) {
    $true
}
Else {
    $false
}

# Remediation; run as user credentials

$TeamsPath = [System.IO.Path]::Combine($env:LOCALAPPDATA, 'Microsoft', 'Teams')
$TeamsUpdateExePath = [System.IO.Path]::Combine($env:LOCALAPPDATA, 'Microsoft', 'Teams', 'Update.exe')

Try
{
    If (Test-Path -Path $TeamsUpdateExePath) {
        Write-Host "Uninstalling Teams process"

        # Uninstall app
        $proc = Start-Process -FilePath $TeamsUpdateExePath -ArgumentList "-uninstall -s" -PassThru
        $proc.WaitForExit()
    }
    If (Test-Path -Path $TeamsPath) {
        Remove-Item –Path $TeamsPath -Recurse
    }
}
Catch
{
    Write-Error -ErrorRecord $_
    Exit /b 1
}