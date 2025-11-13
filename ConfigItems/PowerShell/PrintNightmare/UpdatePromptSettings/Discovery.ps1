# Discovery

$pointAndPrintKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint'
$updatePromptProperty = 'UpdatePromptSettings'

# Detect if the Property exists
If (Get-ItemProperty -Path $pointAndPrintKey -Name $updatePromptProperty -ErrorAction SilentlyContinue) {
    # Property found; return $false (non-compliant)
    $false
}
Else {
    # Property not found; return $true (compliant)
    $true
}