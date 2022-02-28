If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.XboxGamingOverlay'}) {
$true }
Else {
$false
}