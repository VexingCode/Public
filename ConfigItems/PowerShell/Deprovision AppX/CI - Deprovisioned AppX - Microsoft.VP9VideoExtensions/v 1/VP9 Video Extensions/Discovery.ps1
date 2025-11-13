If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.VP9VideoExtensions'}) {
$true }
Else {
$false
}