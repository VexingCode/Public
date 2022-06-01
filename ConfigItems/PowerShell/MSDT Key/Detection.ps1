# Detection

# Built from the suggestions here: https://msrc-blog.microsoft.com/2022/05/30/guidance-for-cve-2022-30190-microsoft-support-diagnostic-tool-vulnerability/

# Create the HKCR PSDrive if it does not exist; its not there by default
If (Get-PSDrive HKCR -ErrorAction SilentlyContinue) {
    # Drive exists; do nothing
}
Else {
    # Drive does not exist
    New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR | Out-Null
}

# Set the key parameter
$msdtKey = 'HKCR:\ms-msdt'

# Test if the key exists
If (Test-Path $msdtKey) {
    # Return $false for non-compliant
    return $false
}
Else {
    # Return $true for compliant
    return $true
}