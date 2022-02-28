If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.3DBuilder'}) {
$true }
Else {
$false
}