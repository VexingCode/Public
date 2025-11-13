If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.XboxGameOverlay'}) {
$true }
Else {
$false
}