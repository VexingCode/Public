# This is the Detection Method for the Intune Win32 Application

# Set the variables for the registry key and properties
$smsHKLM = 'HKLM:\SOFTWARE\CompanyName'
$smsAP = 'SMSOSD-AutoPilot'
$smsType = 'SMSOSD-Type'

# Test if the CompanyName registry key even exists; no point in continuing it if doesn't
If (!(Test-Path HKLM:\SOFTWARE\CompanyName)) {
    # It does not, so exit with why
    Write-Output "The $smsHKLM registry key does not exist."
    Exit 1
}

# Test if the AutoPilot property exists, and that its set to True
If (Get-ItemProperty -Path $smsHKLM -Name $smsAP -ErrorAction SilentlyContinue) {
    If (!((Get-ItemPropertyValue -Path $smsHKLM -Name $smsAP) -eq 'True')) {
        # The value is not True, so output why and exit with error
        Write-Output "$smsAP property does not equal True."
        Exit 1
    }
}
Else {
    # It does not, so output why and exit with error
    Write-Output "The $smsAP property does not exist."
    Exit 1
}

# Test if the Type property exists
If (Get-ItemProperty -Path $smsHKLM -Name $smsType -ErrorAction SilentlyContinue) {
    # It exists, so get the value
    $smsTypeValue = Get-ItemPropertyValue -Path $smsHKLM -Name $smsType
    # Create an array of our builds; this correlated with the TSVars we set
    $builds = @('STD','KSK','LPTP')
    # Test if the Type property value is one of our builds
    If ($smsTypeValue -in $builds){
        # The value matches a known good, so output why and exit with success
        Write-Output "Success! Deployment type is set to $smsTypeValue."
        Exit 0
    }
    Else {
        # It does not match a known good, so output why and exit with error
        Write-Output "The $smsType property, $smsTypeValue, does not match a known good value."
        Exit 1
    }
}
Else {
    # It does not exist, so output why and exit with error
    Write-Output "The $smsType property does not exist."
    Exit 1
}