If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.WindowsFeedbackHub'}) {
$true }
Else {
$false
}