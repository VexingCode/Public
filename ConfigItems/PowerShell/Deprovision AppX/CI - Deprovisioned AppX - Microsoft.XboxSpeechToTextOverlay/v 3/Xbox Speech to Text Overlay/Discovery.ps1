If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.XboxSpeechToTextOverlay'}) {
$true }
Else {
$false
}