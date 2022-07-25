# Discovery

$winlogonRegKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'

# Detect if the Property exists
If (Get-ItemProperty -Path $winlogonRegKey -Name ForceAutoLogon -ErrorAction SilentlyContinue) {
    # Property found; test to see if the AutoAdminLogon value is 1
    If ((Get-ItemPropertyValue -Path $winlogonRegKey -Name ForceAutoLogon) -eq 1) {
        # Property value -eq 1; return $true
        $true
    }
    Else {
        # Property value -ne 1; return $false
        $false
    }
}
Else {
    # Property not found; return $false
    $false
}