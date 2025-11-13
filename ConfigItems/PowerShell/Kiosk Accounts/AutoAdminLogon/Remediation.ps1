# Remediation

$winlogonRegKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'

# Set the property to 1
Set-ItemProperty -Path $winlogonRegKey -Name AutoAdminLogon -Value 1