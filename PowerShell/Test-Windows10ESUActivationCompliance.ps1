$osVersion = (Get-CimInstance Win32_OperatingSystem).Version

# If Windows 11, exit silently—no compliance key returned
if ([version]$osVersion -ge [version]"10.0.22000") {
    exit 0
}

# Otherwise, evaluate ESU license status
$activationIds = @(
    "f520e45e-7413-4a34-a497-d2765967d094",
    "1043add5-23b1-4afb-9a0f-64343c8f3f8d",
    "83d49986-add3-41d7-ba33-87c7bfb5c0fb"
)

$licensed = $false
foreach ($id in $activationIds) {
    $result = cscript.exe /nologo C:\Windows\System32\slmgr.vbs /dlv $id 2>&1
    if ($result -match "License Status:\s+Licensed") {
        $licensed = $true
        break
    }
}

$hash = @{ ESUStatus = if ($licensed) { "Licensed" } else { "Unlicensed" } }
return $hash | ConvertTo-Json -Compress