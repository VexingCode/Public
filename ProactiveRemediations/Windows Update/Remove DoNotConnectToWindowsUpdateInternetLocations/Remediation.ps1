# Remediation

$wuKey = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate'
$wuProperty = 'DoNotConnectToWindowsUpdateInternetLocations'

Remove-ItemProperty -Path $wuKey -Name $wuProperty -Force