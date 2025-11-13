# Discovery
# Validate if PowerShell v2 is enabled on devices (this is bad, m'kay?)

If ((Get-WindowsOptionalFeature -FeatureName MicrosoftWindowsPowerShellV2 -Online).State -eq 'Disabled') {
    $true
}
Else {
    $false
}