# Remediation

$pointAndPrintKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint'
$warnInstallProperty = 'NoWarningNoElevationOnInstall'

Remove-ItemProperty -Path $pointAndPrintKey -Name $warnInstallProperty -Force -ErrorAction SilentlyContinue