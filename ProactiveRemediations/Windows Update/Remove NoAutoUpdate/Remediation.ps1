# Remediation

$wuAUKey = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU'
$wuAUProperty = 'NoAutoUpdate'

Remove-ItemProperty -Path $wuAUKey -Name $wuAUProperty -Force