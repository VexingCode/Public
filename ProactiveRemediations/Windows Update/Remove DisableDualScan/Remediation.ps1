# Remediation

$wuKey = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate'
$wuProperty = 'DisableDualScan'

Remove-ItemProperty -Path $wuKey -Name $wuProperty -Force