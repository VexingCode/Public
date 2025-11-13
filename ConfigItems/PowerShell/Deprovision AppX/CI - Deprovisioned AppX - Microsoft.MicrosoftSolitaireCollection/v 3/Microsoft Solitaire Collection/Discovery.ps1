If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.MicrosoftSolitaireCollection'}) {
$true }
Else {
$false
}