# Remediation

# Set vars
$DefaultUserName = 'kioskUser0'
$winlogonRegKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
$winlogonProperties = 'DefaultDomainName','DefaultUserName','ForceAutoLogon'
$logonUIRegKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI'
$logonUIProperties = 'LastLoggedOnUser','LastLoggedOnUserSID'


# Test for the DefaultDomainName, DefaultUserName, and ForceAutoLogon properties; delete them if found
ForEach ($wlProperty in $winlogonProperties) {
    If (Get-ItemProperty -Path $winlogonRegKey -Name $wlProperty -ErrorAction SilentlyContinue) {
        # Property found; remove it
        Remove-ItemProperty -Path $winlogonRegKey -Name $wlProperty -Force
    }
}

# Test for the AutoAdminLogon property; set value to 0
If (Get-ItemProperty -Path $winlogonRegKey -Name AutoAdminLogon -ErrorAction SilentlyContinue) {
    # Property found; set the property value to 0 (Default on Win11)
    Set-ItemProperty -Path $winlogonRegKey -Name AutoAdminLogon -Value 0
}

# Clear the LastUsedUsername property
If (Get-ItemProperty -Path $winlogonRegKey -Name 'LastUsedUsername' -ErrorAction SilentlyContinue) {
    Set-ItemProperty -Path $winlogonRegKey -Name LastUsedUsername -Value ''
}

# Clear the LastLoggedOnUser and LastLoggedOnUserSID properties
ForEach ($luProperty in $logonUIProperties) {
    If (Get-ItemProperty -Path $logonUIRegKey -Name $luProperty -ErrorAction SilentlyContinue) {
        Set-ItemProperty -Path $logonUIRegKey -Name $luProperty -Value ''
    }
}

# Check if the user 'kioskUser0' exists
If (Get-LocalUser $DefaultUserName) {
    # Check if the user 'kioskUser0' is logged in
    $Sessions = quser | Select-String -Pattern $DefaultUserName

    # If the user is logged in, log them out
    If ($Sessions) {
        $SessionId = ($Sessions -split '\s+')[2]
        logoff $SessionId
    }

    # Delete the user account
    Remove-LocalUser -Name $DefaultUserName
}