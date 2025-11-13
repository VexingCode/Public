# Detection

$wuKey = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate'
$wuProperty = 'DisableDualScan'

If (!(Test-Path $wuKey -ErrorAction SilentlyContinue)) {
    # Registry key does not exist so we assume it is compliant; exit 0
    exit 0
} Else {
    # Validate that the property actually exists with Get-ItemProperty
    If (Get-ItemProperty $wuKey -Name $wuProperty -ErrorAction SilentlyContinue) {
        # The property exists; regardless of its set to 0 (good) or 1 (bad), we are going to nuke it; exit 1
        exit 1
    } Else {
        # The property does not exist; exit 0
        exit 0
    }
}