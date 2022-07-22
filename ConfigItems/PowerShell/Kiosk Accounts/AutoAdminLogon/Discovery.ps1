# Discovery

$winlogonRegKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'

# Test to see if the AutoAdminLogon value is 1
If ((Get-ItemPropertyValue -Path $winlogonRegKey -Name AutoAdminLogon) -eq 1) {
    $true
}
Else {
    $false
}