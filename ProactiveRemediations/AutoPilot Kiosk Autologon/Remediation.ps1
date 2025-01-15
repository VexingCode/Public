# Remediation

# Set vars
$DefaultDomainName = '.'
$DefaultUserName = 'kioskUser0'
$winlogonRegKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'

# Test for the DefaultDomainName property; create/set it, if not
If (Get-ItemProperty -Path $winlogonRegKey -Name DefaultDomainName -ErrorAction SilentlyContinue) {
    # Property found; set the property value to $DefaultDomainName
    Set-ItemProperty -Path $winlogonRegKey -Name DefaultDomainName -Value $DefaultDomainName
}
Else {
    # Property not found; create it and set the value to $DefaultDomainName
    New-ItemProperty -Path $winlogonRegKey -Name DefaultDomainName -PropertyType String -Value $DefaultDomainName
}

# Test for the DefaultUserName property; create/set it, if not
If (Get-ItemProperty -Path $winlogonRegKey -Name DefaultUserName -ErrorAction SilentlyContinue) {
    # Property found; set the property value to $DefaultUserName
    Set-ItemProperty -Path $winlogonRegKey -Name DefaultUserName -Value $DefaultUserName
}
Else {
    # Property not found; create it and set the value to $DefaultUserName
    New-ItemProperty -Path $winlogonRegKey -Name DefaultUserName -PropertyType String -Value $DefaultUserName
}

# Test for the AutoAdminLogon property; create/set it, if not
If (Get-ItemProperty -Path $winlogonRegKey -Name AutoAdminLogon -ErrorAction SilentlyContinue) {
    # Property found; set the property value to 1
    Set-ItemProperty -Path $winlogonRegKey -Name AutoAdminLogon -Value 1
}
Else {
    # Property not found; create it and set the value to 1
    New-ItemProperty -Path $winlogonRegKey -Name AutoAdminLogon -PropertyType DWord -Value 1
}

# Test for the ForceAutoLogon property; create/set it, if not
If (Get-ItemProperty -Path $winlogonRegKey -Name ForceAutoLogon -ErrorAction SilentlyContinue) {
    # Property found; set the property value to 1
    Set-ItemProperty -Path $winlogonRegKey -Name ForceAutoLogon -Value 1
}
Else {
    # Property not found; create it and set the value to 1
    New-ItemProperty -Path $winlogonRegKey -Name ForceAutoLogon -PropertyType DWord -Value 1
}