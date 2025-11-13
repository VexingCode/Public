If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.ZuneMusic'}) {
$true }
Else {
$false
}