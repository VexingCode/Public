If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.WindowsAlarms'}) {
$true }
Else {
$false
}