If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.BingWeather'}) {
$true }
Else {
$false
}