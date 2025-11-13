# Detection

# Set vars
$DefaultUserName = 'kioskUser0'
$winlogonRegKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'

# Test for the builtin kioskUser0 account
If (Get-LocalUser 'kioskUser0') {
    # kioskUser0 account found; exit 1
    Write-Warning "kioskUser0 account found; exit 1"
}

# Test for the DefaultDomainName property
If (Get-ItemProperty -Path $winlogonRegKey -Name DefaultDomainName -ErrorAction SilentlyContinue) {
    # Property found; exit 1
    Write-Warning "DefaultDomainName property found; exit 1"
    exit 1
}

# Test for the DefaultUserName property
If (Get-ItemProperty -Path $winlogonRegKey -Name DefaultUserName -ErrorAction SilentlyContinue) {
    # Property found; exit 1
    Write-Warning "DefaultUserName property found; exit 1"
    exit 1
}

# Test for the AutoAdminLogon property
If (Get-ItemProperty -Path $winlogonRegKey -Name AutoAdminLogon -ErrorAction SilentlyContinue) {
    # Property found; validate value
    If ((Get-ItemPropertyValue -Path $winlogonRegKey -Name AutoAdminLogon -ErrorAction SilentlyContinue) -ne 0) {
        Write-Warning "AutoAdminLogon property found, but the value is incorrect; exit 1"
        exit 1
    }
}

# Test for the ForceAutoLogon property
If (Get-ItemProperty -Path $winlogonRegKey -Name ForceAutoLogon -ErrorAction SilentlyContinue) {
    # Property found; exit 1
    Write-Warning "ForceAutoLogon property found; exit 1"
    exit 1
}

exit 0