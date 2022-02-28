If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.YourPhone'}) {
$true }
Else {
$false
}