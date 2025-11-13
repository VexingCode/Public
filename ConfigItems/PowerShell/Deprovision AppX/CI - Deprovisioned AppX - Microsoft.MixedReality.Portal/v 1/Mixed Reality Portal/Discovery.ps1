If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.MixedReality.Portal'}) {
$true }
Else {
$false
}