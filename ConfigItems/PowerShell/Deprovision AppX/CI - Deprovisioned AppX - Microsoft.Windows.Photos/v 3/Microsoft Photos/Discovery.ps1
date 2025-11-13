If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.Windows.Photos'}) {
$true }
Else {
$false
}