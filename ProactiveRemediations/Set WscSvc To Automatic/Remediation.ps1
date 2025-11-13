# Remediation

$wscSvcKey = 'HKLM:\SYSTEM\CurrentControlSet\Services\wscsvc'
$startProperty = 'Start'
$startValue = '2'

Try {
    Set-ItemProperty -Path $wscSvcKey -Name $startProperty -Value $startValue -ErrorAction Stop
    exit 0
} Catch {
    $_.Exception.Message
    exit 1
}