# Discovery

$pointAndPrintKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint'
$warnInstallProperty = 'NoWarningNoElevationOnInstall'

# Detect if the Property exists
If (Get-ItemProperty -Path $pointAndPrintKey -Name $warnInstallProperty -ErrorAction SilentlyContinue) {
    # Property found; return $false (non-compliant)
    $false
}
Else {
    # Property not found; return $true (compliant)
    $true
}