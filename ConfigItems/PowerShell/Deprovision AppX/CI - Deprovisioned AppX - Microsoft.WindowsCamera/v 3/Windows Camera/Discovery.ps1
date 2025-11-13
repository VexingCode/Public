If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.Camera'}) {
$true }
Else {
$false
}