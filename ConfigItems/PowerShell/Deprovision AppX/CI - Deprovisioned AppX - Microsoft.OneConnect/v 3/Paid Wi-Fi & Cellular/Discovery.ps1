If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.OneConnect'}) {
$true }
Else {
$false
}