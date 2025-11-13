# Define the AppX products to remove
$appXPackages = @(
    'DellInc.DellSupportAssistforPCs'
    'DellInc.DellDigitalDelivery'
    'DellInc.PartnerPromo'
 )

# Look through the AppX packages
ForEach ($appX in $appXPackages) {
    # Detect if the AppX package exists
    If (Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -Match $appX } ) {
        # Get the Provisioning package name
        $AppProvisioningPackageName = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -Match $appX } | Select-Object -ExpandProperty PackageName
        # Remove the Provisioning package
        Remove-AppxProvisionedPackage -PackageName $AppProvisioningPackageName -Online -ErrorAction Stop
    }
}

# Define the products to remove
# Need to add -silent to Optimizer
$products = $(
    'Dell SupportAssist OS Recovery Plugin for Dell Update'
    'Dell SupportAssist Remediation'
    'Dell Optimizer Service'
    'Dell Digital Delivery'
    'Dell Digital Delivery Services'
    'SupportAssist Recovery Agent'
    'Dell SupportAssist'
)

$optimizerArg = '-silent'
$supportAssistArg = '/quiet'

Function Uninstall-Application {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string[]]
        $Application
    )

    # Clear the variables (I've seen them not clear before, in the loop)
    $32bit = $null
    $64bit = $null

    # Now we look for the Product, and its uninstall string in the registry
    $64bit = Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' | Select-Object DisplayName, DisplayVersion, UninstallString, PSChildName | Where-Object { $_.DisplayName -match "^*$Application*"}
    $32bit = Get-ItemProperty 'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' | Select-Object DisplayName, DisplayVersion, UninstallString, PSChildName | Where-Object { $_.DisplayName -match "^*$Application*"}

    # If both values are $null, skip
    If ($null -eq $64bit -and $null -eq $32bit) {
        # Product not found under the unininstall registry keys
        Write-Output "$product not found under the uninstall registry keys."
    }
    Else {
        # If the $64bit var is empty or the count is 0...
        If ($64bit -eq "" -or $64bit.Count -eq 0) {
            # Set the uninstall variable
            $32bitUninstall = $32bit.UninstallString
            # Uninstall 32bit application
            Switch ($32bit.DisplayName.Count) {
                0 { Write-Output "Cannot find $product under the 32bit registry." }
                1 {
                    If ($32bit -match "msiexec.exe") {
                        Write-Output "Attempting to uninstall $product via the Uninstall-Package cmdlet."
                        Get-Package $product -ErrorAction SilentlyContinue | Uninstall-Package -AllVersions -Force -SkipDependencies # -WhatIf
                    }
                    Else {
                        # Grab the exe location from the registry key
                        $32bitEXE = (($32bitUninstall -Split '"')[1]).Trim()
                        # Grab the vars off the Uninstall Strings
                        $32bitEXEArguments = (($32bitUninstall -Split '"')[-1]).Trim()
                        # If Optimizer, append -silent
                        If ($product -eq 'Dell Optimizer Service') {
                            $32bitEXEArguments = $32bitEXEArguments + " " + $optimizerArg
                        }
                        ElseIf ($product -eq 'Dell SupportAssist Remediation') {
                            $32bitEXEArguments = $32bitEXEArguments + " " + $supportAssistArg
                        }
                        ElseIf ($product -eq 'Dell SupportAssist OS Recovery Plugin for Dell Update') {
                            $32bitEXEArguments = $32bitEXEArguments + " " + $supportAssistArg
                        }
                        # Test if the file exists in that path
                        If (Test-Path $32bitEXE -ErrorAction SilentlyContinue) {
                            # Exe exists in that location, attempting uninstall
                            Write-Output "Attempting to uninstall $product via specified exe."
                            Start-Process $32bitEXE -ArgumentList $32bitEXEArguments -Wait
                        }
                    }
                }
                Default { Write-Output "Cannot find $product under the 32bit registry." }
            }
        }
        Else {
            # Set the uninstall variable
            $64bitUninstall = $64bit.UninstallString
            # Uninstall 64bit application
            Switch ($64bit.DisplayName.Count) {
                0 { Write-Output "Cannot find $product under the 64bit registry." }
                1 {
                    If ($64bit -match "msiexec.exe") {
                        Write-Output "Attempting to uninstall $product via the Uninstall-Package cmdlet."
                        Get-Package $product -ErrorAction SilentlyContinue | Uninstall-Package -AllVersions -Force -SkipDependencies # -WhatIf
                    }
                    Else {
                        # Grab the exe location from the registry key
                        $64bitEXE = (($64bitUninstall -Split '"')[1]).Trim()
                        # Grab the vars off the Uninstall Strings
                        $64bitEXEArguments = (($64bitUninstall -Split '"')[-1]).Trim()
                        # If Optimizer, append -silent
                        If ($product -eq 'Dell Optimizer Service') {
                            $64bitEXEArguments = $64bitEXEArguments + " " + $optimizerArg
                        }
                        ElseIf ($product -eq 'Dell SupportAssist Remediation') {
                            $64bitEXEArguments = $64bitEXEArguments + " " + $supportAssistArg
                        }
                        ElseIf ($product -eq 'Dell SupportAssist OS Recovery Plugin for Dell Update') {
                            $64bitEXEArguments = $64bitEXEArguments + " " + $supportAssistArg
                        }
                        # Test if the file exists in that path
                        If (Test-Path $64bitEXE -ErrorAction SilentlyContinue) {
                            # Exe exists in that location, attempting uninstall
                            Write-Output "Attempting to uninstall $product via specified exe."
                            Start-Process $64bitEXE -ArgumentList $64bitEXEArguments -Wait
                        }
                    }
                }
                Default { Write-Output "Cannot find $product under the 64bit registry." }
            }
        }
    }
}

# Loop through the products
ForEach ($product in $products) { Uninstall-Application -Application $product }

# Remove the C:\DummyDir
If (Test-Path C:\DummyDir) {
    Remove-Item -LiteralPath 'C:\DummyDir' -Force -Recurse -ErrorAction 'SilentlyContinue'
}

# Links to remove
$links = @(
    'Dell Digital Delivery.lnk'
    'Dell Update.lnk'
    'SupportAssist.lnk'
)

# Loop through the links
ForEach ($link in $links) {
    # Detect whether the link exists
    If (Test-Path C:\Users\Public\Desktop\$link) {
        # Remove the link
        Remove-Item -LiteralPath "C:\Users\Public\Desktop\$link" -Force
    }
}