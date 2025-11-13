If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.ZuneVideo'}) {
$true }
Else {
$false
}