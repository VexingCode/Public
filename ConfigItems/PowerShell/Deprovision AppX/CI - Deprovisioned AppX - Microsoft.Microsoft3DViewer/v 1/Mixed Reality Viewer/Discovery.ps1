If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.Microsoft3DViewer'}) {
$true }
Else {
$false
}