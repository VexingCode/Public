If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.SkypeApp'}) {
$true }
Else {
$false
}