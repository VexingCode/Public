# Remediation

$pointAndPrintKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint'
$updatePromptProperty = 'UpdatePromptSettings'

Remove-ItemProperty -Path $pointAndPrintKey -Name $updatePromptProperty -Force -ErrorAction SilentlyContinue