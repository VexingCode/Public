If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.XboxApp'}) {
$true }
Else {
$false
}