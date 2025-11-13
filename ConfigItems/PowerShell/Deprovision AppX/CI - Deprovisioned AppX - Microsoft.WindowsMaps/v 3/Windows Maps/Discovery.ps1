If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.WindowsMaps'}) {
$true }
Else {
$false
}