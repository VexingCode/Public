# Remediation

# Set vars
$wvdRegKey = 'HKLM:\SOFTWARE\Microsoft\Teams' 
$wvdProperty = 'IsWVDEnvironment'
$wvdPropertyValue = '1'

If (!(Test-Path $wvdRegKey -ErrorAction SilentlyContinue)) {
    Try {
        New-Item -Path $wvdRegKey -Force | Out-Null
        New-ItemProperty $wvdRegKey -Name $wvdProperty -PropertyType DWord -Value $wvdPropertyValue -Force | Out-Null
    } Catch {
        $_.Exception.Message
        exit 1
    }
} Else {
    New-ItemProperty $wvdRegKey -Name $wvdProperty -PropertyType DWord -Value $wvdPropertyValue -Force | Out-Null
}