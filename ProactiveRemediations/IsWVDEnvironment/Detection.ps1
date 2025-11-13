# Detection

# Set vars
$wvdRegKey = 'HKLM:\SOFTWARE\Microsoft\Teams' 
$wvdProperty = 'IsWVDEnvironment'
$wvdPropertyValue = '1'

# Test for the IsWVDEnvironment property
If (Get-ItemProperty -Path $wvdRegKey -Name $wvdProperty -ErrorAction SilentlyContinue) {
    # Property found; validate value
    If (!(Get-ItemPropertyValue -Path $wvdRegKey -Name $wvdProperty -ErrorAction SilentlyContinue) -eq $wvdPropertyValue) {
        Write-Warning "IsWVDEnvironment property found, but the value is incorrect; exit 1"
        exit 1
    }
} Else {
    Write-Warning 'IsWVDEnvironment property not found; exit 1'
    exit 1
}

exit 0