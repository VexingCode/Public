# Remediation

$winlogonRegKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'

# Validate if the Property exists
If (Get-ItemProperty -Path $winlogonRegKey -Name ForceAutoLogon -ErrorAction SilentlyContinue) {
    # Property found; set the property value to 1
    Set-ItemProperty -Path $winlogonRegKey -Name ForceAutoLogon -Value 1
}
Else {
    # Property not found; create it and set the value to 1
    New-ItemProperty -Path $winlogonRegKey -Name ForceAutoLogon -PropertyType DWord -Value 1
}