# Detection

$wscSvcKey = 'HKLM:\SYSTEM\CurrentControlSet\Services\wscsvc'
$startProperty = 'Start'
$startValue = '2'


If (!((Get-ItemPropertyValue -Path $wscSvcKey -Name $startProperty) -eq $startValue)) {
    # The value does not equal 2 (Automatic (delayed start)); exit 1 for non-compliant
    Write-Warning 'WscSvc not set to "2" (Automatic (delayed start)).'
    exit 1
} Else {
    # The value equals 2 (Automatic (delayed start)); exit 0 for compliant
    exit 0
}