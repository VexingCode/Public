# Remediation
# Disable WindowsPowerShellV2

Get-WindowsOptionalFeature -FeatureName MicrosoftWindowsPowerShellV2 -Online | Disable-WindowsOptionalFeature -Online