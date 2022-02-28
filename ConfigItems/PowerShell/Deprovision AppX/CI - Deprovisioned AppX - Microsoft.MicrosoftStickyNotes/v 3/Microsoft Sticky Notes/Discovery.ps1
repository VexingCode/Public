If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.MicrosoftStickyNotes'}) {
$true }
Else {
$false
}