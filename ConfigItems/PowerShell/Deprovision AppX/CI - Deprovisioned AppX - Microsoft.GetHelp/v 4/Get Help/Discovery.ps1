If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.GetHelp'}) {
$true }
Else {
$false
}