# Remediation
# Disable SMB1Protocol

Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol | Disable-WindowsOptionalFeature -Online