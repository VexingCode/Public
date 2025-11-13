# Change into a function with parameters for user(s)/file and group by name or ObjectID

$domain = "@domain.com"
$grpObjID = '74c56591-7172-4de7-be7d-61c288391ac4'

ForEach ($user in $users) {
    $user = $user + $domain
    If (Get-AzureADUser -Filter "userPrincipalName eq '$user'") {
        Write-Host "$user exists. Adding them to Azure Security Group."
        $userCloud = Get-AzureADUser -ObjectId $user
        Add-AzureADGroupMember -ObjectId $grpObjID -RefObjectId $userCloud.ObjectId
    }
    Else {
        Write-Host "$user does not exist!" -ForegroundColor Red
    }
}