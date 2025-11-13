If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.SkreenSketch'}) {
$true }
Else {
$false
}