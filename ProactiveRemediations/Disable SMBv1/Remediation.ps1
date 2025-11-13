# Remediation
# Disable SMB1Protocol (BECAUSE ITS BAD, M'KAY?! IT'S REAL BAD!)

Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol | Disable-WindowsOptionalFeature -Online