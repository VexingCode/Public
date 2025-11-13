Function Get-CMCollectionRuleSummary {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$CollectionIDs,

        [Parameter()]
        [string]$ExportPath
    )

    $log = @()

    ForEach ($collectionId in $CollectionIDs) {
        $collection = Get-CMCollection -Id $collectionId
        If (-not $collection) {
            $log += [pscustomobject]@{
                CollectionName      = "<not found>"
                CollectionID        = $collectionId
                RuleSummary         = "NotFound"
                CanDisableSync      = $false
                RefreshTypeSummary  = "<not found>"
            }
            continue
        }

        $rules = $collection.CollectionRules
        $ruleTypes = @()

        If (-not $rules) {
            $ruleTypes += "Empty"
        } Else {
            ForEach ($rule in $rules) {
                switch ($rule.SmsProviderObjectPath) {
                    'SMS_CollectionRuleDirect'            { $ruleTypes += "DirectAddsOnly" }
                    'SMS_CollectionRuleIncludeCollection' { $ruleTypes += "IncludeCol" }
                    'SMS_CollectionRuleExcludeCollection' { $ruleTypes += "ExcludeCol" }
                    'SMS_CollectionRuleQuery'             { $ruleTypes += "Query" }
                    default                               { $ruleTypes += "UnknownRuleType" }
                }
            }
        }

        $summary = ($ruleTypes | Sort-Object -Unique)
        $canDisable = ($summary -contains "Empty" -and $summary.Count -eq 1) -or
                    ($summary -contains "DirectAddsOnly" -and $summary.Count -eq 1)

        # Normalize RefreshType from the collection itself
        $typeValue = [int]$collection.RefreshType
        switch ($typeValue) {
            0 { $refreshSummary = "Manual" }
            1 { $refreshSummary = "Manual" }
            2 { $refreshSummary = "Periodic" }
            4 { $refreshSummary = "Continuous" }
            6 { $refreshSummary = "Both" }
            default { $refreshSummary = "Unknown" }
        }

        $log += [pscustomobject]@{
            CollectionName      = $collection.Name
            CollectionID        = $collectionId
            RuleSummary         = $summary -join "; "
            CanDisableSync      = $canDisable
            RefreshTypeSummary  = $refreshSummary
        }
    }

    If ($ExportPath) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $finalPath = Join-Path -Path $ExportPath -ChildPath "CollectionRuleSummary-$timestamp.csv"
        $log | Export-Csv -Path $finalPath -NoTypeInformation -Encoding UTF8
        Write-Host "Exported summary to $finalPath"
    }

    return $log
}