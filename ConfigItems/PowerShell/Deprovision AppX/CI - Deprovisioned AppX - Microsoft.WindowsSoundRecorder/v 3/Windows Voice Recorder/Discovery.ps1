If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.WindowsSoundRecorder'}) {
$true }
Else {
$false
}