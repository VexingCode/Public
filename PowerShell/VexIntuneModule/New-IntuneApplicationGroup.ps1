function New-IntuneApplicationGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0)]
        [string]
        $ProductVendor,
        [Parameter(Mandatory,Position=1)]
        [string]
        $ProductName,
        [Parameter(Mandatory,Position=2)]
        [ValidateSet('Available','Required','Update','Uninstall','All')]
        [string]
        $DeploymentType,
        [Parameter(Mandatory,Position=3)]
        [ValidateSet('Device','User','Both')]
        [string]
        $DeploymentTarget,
        [Parameter(Mandatory,Position=4)]
        [ValidateSet('Win','Drd','MacOS','iOS')]
        [string]
        $OperatingSystem,
        [Parameter(Position=5)]
        [ValidateSet('Yes','Both')]
        [string]
        $ExclusionGroup
    )

    # Required -Modules Microsoft.Graph.Beta.Groups

    If (!(Get-MgContext)) {
        Connect-MgGraph
    }

    Function Clean-String {
        param (
            [string]$InputString
        )
        $cleanedString = $InputString.Trim() -replace '[^a-zA-Z0-9\s]', '' -replace '\s+', '-'
        return $cleanedString
    }

    $cleanVendor = Clean-String -InputString $ProductVendor
    $cleanName = Clean-String -InputString $ProductName

    $deploymentTypes = If ($DeploymentType -eq 'All') { 
        'Available', 'Required', 'Update', 'Uninstall'
    } Else { 
        $DeploymentType
    }
    $deploymentTargets = If ($DeploymentTarget -eq 'Both') { 
        'Device','User'
    } Else { 
        $DeploymentTarget
    }

    ForEach ($dt in $deploymentTypes) {
        switch ($dt) {
            'Available' {
                $nameDT = 'AIA'
                $descDT = 'Available install'
            }
            'Required' {
                $nameDT = 'AIR'
                $descDT = 'Required install'
            }
            'Update' {
                $nameDT = 'AUD'
                $descDT = 'Required update'
            }
            'Uninstall' {
                $nameDT = 'AUR'
                $descDT = 'Required uninstall'
            }
        }

        ForEach ($tgt in $deploymentTargets) {
            switch ($tgt) {
                'Device' {
                    $nameTgt = 'D'
                    $descTgt = 'devices'
                }
                'User' {
                    $nameTgt = 'U'
                    $descTgt = 'users'
                }
            }

            $compiledName = "MEM-$OperatingSystem-$nameDT-$cleanVendor-$cleanName-$nameTgt"
            $compiledDesc = "$descDT group targeting $descTgt, for the $ProductVendor $ProductName application."

            $Body = @{
                DisplayName     = $compiledName
                Description     = $compiledDesc
                MailEnabled     = $false
                MailNickname    = 'NotSet'
                SecurityEnabled = $true
            }

            New-MgBetaGroup -Body $Body

            If ($ExclusionGroup -eq 'Yes' -or $ExclusionGroup -eq 'Both') {
                $descDTLower = $descDT.ToLower()
                $compiledNameEx = "MEM-$OperatingSystem-$nameDT-ExGrp-$cleanVendor-$cleanName-$nameTgt"
                $compiledDescEx = "Use for exclusions to the $descDTLower group targeting $descTgt, for the $ProductVendor $ProductName application."

                $BodyEx = @{
                    DisplayName     = $compiledNameEx
                    Description     = $compiledDescEx
                    MailEnabled     = $false
                    MailNickname    = 'NotSet'
                    SecurityEnabled = $true
                }

                New-MgBetaGroup -Body $BodyEx
            }
        }
    }
}