If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.WebpImageExtension'}) {
$true }
Else {
$false
}