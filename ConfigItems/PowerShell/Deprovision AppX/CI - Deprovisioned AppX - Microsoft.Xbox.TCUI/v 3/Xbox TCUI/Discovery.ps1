If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.Xbox.TCUI'}) {
$true }
Else {
$false
}