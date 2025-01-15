# Discovery
# Validate if SMBv1 is enabled on devices (this is _real_ bad, m'kay?)

If ((Get-WindowsOptionalFeature -FeatureName SMB1Protocol -Online).State -eq 'Disabled') {
    $true
}
Else {
    $false
}