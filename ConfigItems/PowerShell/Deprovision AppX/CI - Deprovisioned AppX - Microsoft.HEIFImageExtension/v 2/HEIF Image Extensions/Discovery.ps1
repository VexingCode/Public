If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.HEIFImageExtension'}) {
$true }
Else {
$false
}