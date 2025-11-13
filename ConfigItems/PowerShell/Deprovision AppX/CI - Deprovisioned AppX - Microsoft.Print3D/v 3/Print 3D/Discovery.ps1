If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.Print3D'}) {
$true }
Else {
$false
}