If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.Office.OneNote'}) {
$true }
Else {
$false
}