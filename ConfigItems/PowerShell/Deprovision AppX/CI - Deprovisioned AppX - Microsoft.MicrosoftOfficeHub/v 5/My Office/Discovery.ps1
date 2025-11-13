If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.MicrosoftOfficeHub'}) {
$true }
Else {
$false
}