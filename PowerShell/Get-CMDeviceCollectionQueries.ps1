# Get all of the Device collections in ConfigMgr (This can take a long time! Let it run.)
$collections = Get-CMDeviceCollection | Select-Object Name
# Loop through each of the collections
ForEach ($collection in $collections) {
    Write-Output "Collection is $collection."
    # Search for Query Membership Rules; if none are found it will not error
    $col = Get-CMDeviceCollectionQueryMembershipRule -CollectionName $collection
    Write-Output "Collection data is:"
    Write-Output $col
    # Assign the Query IDs to a variable
    $ids = $col.QueryID
    Write-Output "IDs are:"
    Write-Output $ids
    # Check if the variable is $null, indicating no rules
    If ($null -ne $ids) {
        Write-Output "IDs are not null."
        # Loop through each of the rules
        ForEach ($id in $ids) {
            Write-Output "Current working ID is $id."
            # Gather the query data
            $queryRule = $col | Where-Object {$_.QueryID -eq $id}
            Write-Output "Gathered the following data for the query:"
            Write-Output $queryRule
            # Assign the RuleName
            $ruleName = $queryRule.RuleName
            # Assign the QueryExpression
            $ruleExpression = $queryRule.QueryExpression
            # Create the PSCustomObject
            $queryResult = [PSCustomObject]@{
                CollectionName = $collection;
                QueryName = $ruleName;
                WQLExpression = $ruleExpression;
            }
            # Export the result to the CSV
            Write-Output "Exporting the following result to the CSV:"
            Write-Output $queryResult
            $queryResult | Export-Csv -Path FileSystem::"\\LocalHost\c$\Temp\Collection-Query-Export.csv" -NoTypeInformation -Append
        }
    }
}