If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.MSPaint'}) {
$true }
Else {
$false
}