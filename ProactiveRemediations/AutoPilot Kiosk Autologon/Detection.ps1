# Detection

# PRTrigger0001

# Set vars
$DefaultDomainName = '.'
$DefaultUserName = 'kioskUser0'
$winlogonRegKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'

# Test for the DefaultDomainName property
If (Get-ItemProperty -Path $winlogonRegKey -Name DefaultDomainName -ErrorAction SilentlyContinue) {
    # Property found; validate value
    If (!(Get-ItemPropertyValue -Path $winlogonRegKey -Name DefaultDomainName -ErrorAction SilentlyContinue) -eq $DefaultDomainName) {
        Write-Warning "DefaultDomainName property found, but the value is incorrect; exit 1"
        exit 1
    }
} Else {
    Write-Warning 'DefaultDomainName property not found; exit 1'
    exit 1
}

# Test for the DefaultUserName property
If (Get-ItemProperty -Path $winlogonRegKey -Name DefaultUserName -ErrorAction SilentlyContinue) {
    # Property found; validate value
    If (!(Get-ItemPropertyValue -Path $winlogonRegKey -Name DefaultUserName -ErrorAction SilentlyContinue) -eq $DefaultUserName) {
        Write-Warning "DefaultUserName property found, but the value is incorrect; exit 1"
        exit 1
    }
} Else {
    Write-Warning 'DefaultUserName property not found; exit 1'
    exit 1
}

# Test for the AutoAdminLogon property
If (Get-ItemProperty -Path $winlogonRegKey -Name AutoAdminLogon -ErrorAction SilentlyContinue) {
    # Property found; validate value
    If ((Get-ItemPropertyValue -Path $winlogonRegKey -Name AutoAdminLogon -ErrorAction SilentlyContinue) -ne 1) {
        Write-Warning "AutoAdminLogon property found, but the value is incorrect; exit 1"
        exit 1
    }
} Else {
    Write-Warning 'AutoAdminLogon property not found; exit 1'
    exit 1
}

# Test for the ForceAutoLogon property
If (Get-ItemProperty -Path $winlogonRegKey -Name ForceAutoLogon -ErrorAction SilentlyContinue) {
    # Property found; validate value
    If ((Get-ItemPropertyValue -Path $winlogonRegKey -Name ForceAutoLogon -ErrorAction SilentlyContinue) -ne 1) {
        Write-Warning "ForceAutoLogon property found, but the value is incorrect; exit 1"
        exit 1
    }
} Else {
    Write-Warning 'ForceAutoLogon property not found; exit 1'
    exit 1
}

exit 0