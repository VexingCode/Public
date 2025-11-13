# Define the variables
$clientId = ""
$clientSecret = ""
$tenantId = ""
$outputFilePath = 'D:\Temp\IntuneAutomationProcess\Data'
#$outputFilePath = 'C:\Temp\IntuneAutomationProcess\Data'
$outputFileName = 'Intune-Mobile-Device-Export'

# Convert the Client Secret to a Secure String
$SecureClientSecret = ConvertTo-SecureString -String $clientSecret -AsPlainText -Force

# Create a PSCredential Object Using the Client ID and Secure Client Secret
$ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $clientId, $SecureClientSecret

# Connect to Microsoft Graph Using the Tenant ID and Client Secret Credential
Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $ClientSecretCredential -NoWelcome

# Remove previous report files if they exist
If (Get-ChildItem -Path "$outputFilePath\$outputFileName*" -Include *.zip, *.csv) {
    Remove-Item "$outputFilePath\$outputFileName*" -Force -Verbose
}

# Define the JSON object without a filter
$body = @{
    reportName = "DevicesWithInventory"
    format = "csv"
    localizationType = "LocalizedValuesAsAdditionalColumn"
    select = @(
        "IMEI",
        "PhoneNumber",
        "ICCID",
        "SerialNumber",
        "Manufacturer",
        "Model",
        "CreatedDate",
        "UserName",
        "UPN",
        "UserId",
        "LastContact",
        "OS",
        "SubscriberCarrierNetwork",
        "ComplianceState",
        "InGracePeriodUntil"
    )
}

# Convert the hashtable to a JSON string
$jsonBody = $body | ConvertTo-Json -Depth 3

# Use the JSON string in the Invoke-MgGraphRequest
$reportRequest = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/reports/exportJobs" -Body $jsonBody -ContentType "application/json"

# Initialize the report status
$reportStatus = $null

# Loop to check the report status until it is 'completed'
Do {
    Start-Sleep -Seconds 10 # Wait for 10 seconds before checking the status again
    $reportStatus = Get-MgDeviceManagementReportExportJob -DeviceManagementExportJobId $reportRequest.Id
    # $reportStatus = Get-MgBetaDeviceManagementReportExportJob -DeviceManagementExportJobId $reportRequest.Id
} While ($reportStatus.Status -ne 'completed')

# Download the report using Invoke-WebRequest
$zip = "$outputFilePath\$outputFileName.zip"
Invoke-WebRequest -Uri $reportStatus.Url -OutFile $zip

# Unzip the archive to extract the file, then rename the file
Expand-Archive -LiteralPath $zip -DestinationPath $outputFilePath -Force
Rename-Item -LiteralPath "$outputFilePath\$($reportRequest.Id).csv" -NewName "$outputFileName.csv"

# Delete the archive
Remove-Item -Path $zip -Force

# Import the CSV file
$csvDevices = Import-Csv -Path "$outputFilePath\$outputFileName.csv"

# Process each device in a single loop
$processedDevices = @()

ForEach ($device in $csvDevices) {
    # Clone IMEI to IMEI_UniqueId
    $device | Add-Member -MemberType NoteProperty -Name IMEI_UniqueId -Value $device.IMEI

    # Clean up the "Phone number" column
    If ($device.'Phone number') {
        $cleanedPhoneNumber = ($device.'Phone number' -replace '[^\d]', '') # Remove non-numeric characters
        If ($cleanedPhoneNumber -match '^1\d{10}$') {
            $cleanedPhoneNumber = $cleanedPhoneNumber.Substring(1) # Remove leading '1' if it's part of an 11-digit number
        }
        $device.'Phone number' = $cleanedPhoneNumber
    }

    # Apply corrected filtering criteria:
    # Keep the row if:
    # - It has a SubscriberCarrierNetwork (not null or blank)
    # - OR OS is iOS, Android
    If (($device.'Subscriber Carrier' -ne $null -and $device.'Subscriber Carrier' -ne "") -or
        $device.OS -match "iOS|Android") {
        $processedDevices += $device
    }
}

# Export the updated CSV file
$processedDevices | Export-Csv -Path "$outputFilePath\$outputFileName.csv" -NoTypeInformation -Force
Write-Host "Exported to $outputFilePath\$outputFileName.csv"
