If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.XboxIdentityProvider'}) {
$true }
Else {
$false
}