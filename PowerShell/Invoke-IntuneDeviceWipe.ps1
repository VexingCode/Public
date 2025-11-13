Function Invoke-DevDeviceWipe {
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory)]
        [ValidateSet('Windows','Android','MacOS','iOS')]
        [string]
        $OS,
        # Graph return: deviceName
        [Parameter()]
        [string]
        $DeviceName,
        # Graph return: id
        [Parameter()]
        [string]
        $DeviceId,
        # Graph return: imei
        [Parameter()]
        [string]
        $DeviceIMEI,
        # Graph return: serialNumber
        [Parameter()]
        [string]
        $DeviceSerial
    )

    Begin {
        Switch ($OS) {
            {$_ -in ('Windows', 'MacOS')} {
                If ($DeviceIMEI) {
                    Throw "For $_, you cannot specify a DeviceIMEI."
                } ElseIf ((($null -ne $DeviceName) -and ($null -ne $DeviceId) -and ($null -ne $DeviceSerial)) -gt 1) {
                    Throw "For $_, you can only specify one of DeviceName, DeviceId, or DeviceSerial."
                }
            }
            {$_ -in ('Android', 'iOS')} {
                If ($DeviceName) {
                    Throw "For $_, you cannot specify a DeviceName."
                } ElseIf ((($null -ne $DeviceId) -and ($null -ne $DeviceIMEI) -and ($null -ne $DeviceSerial)) -gt 1) {
                    Throw "For $_, you can only specify one of DeviceId, DeviceIMEI, or DeviceSerial."
                }
            }
        }
    } Process {
        Function Export-ALBCode {
            # Create the Con folder if it doesn't exist
            If (!(Test-Path 'C:\ProgramData\Con')) {
                New-Item 'C:\ProgramData\Con' -ItemType Directory | Out-Null
            }
    
            # Set the parameters, and block
            $albcRetrievalDate = Get-Date -Format "yyyyMMddTHHmmssZ"
            $fileName = "ALBC-$DeviceId-$albcRetrievalDate.txt"
            $fileValueBlock = @(
                "Device Name: $($deviceInfo.Value.deviceName)"
                "Device Id: $DeviceId"
                "ActivateLock Bypass Code: $albCode"
                "Date of Retrieval: $albcRetrievalDate"
            )
    
            # Create the file, with the content
            Set-Content -Path "C:\ProgramData\Con\$fileName" -Value $fileValueBlock
    
            Write-Host "The information has been saved, locally, to " -NoNewline
            Write-Host "C:\ProgramData\Con\" -NoNewline -ForegroundColor Green
            Write-Host $fileName -ForegroundColor Cyan
        }

        # Variables
        $managedDevicesUri = '/beta/deviceManagement/managedDevices'

        If ($DeviceName) {
            <# 
            Apple devices often use a "[Name]'s [Device]" template; this causes RH curly single quotes in Entra/Intune
            Since the desktop teams would likely just be using the apostrophe key, we need to replace it with
            %E2%80%99, which is the percent-encoded representation of the RH curly single quote.

            We are making the (inevitably incorrect) assumption that this is the only weird character we will find
            that would throw off the Graph filter query.
            #>
            Write-Host 'DeviceName provided.'
            $DeviceName = $DeviceName.Replace("'","%E2%80%99")
            Write-Host "DeviceName is: $DeviceName"

            # Set the URI to filter on device name
            $deviceUri = "$managedDevicesUri/`?`$filter=deviceName eq '$DeviceName'"
            Write-Host "DeviceUri is: $deviceUri"
        } ElseIf ($DeviceId) {
            # Set the URI to grab the device id (Note: This is the INTUNE device id)
            $deviceUri = "$managedDevicesUri('$DeviceId')"
        } ElseIf ($DeviceIMEI) {
            # Set the URI to filter on the IMEI
            $deviceUri = "$managedDevicesUri/`?`$filter=imei eq '$DeviceIMEI'"
        } ElseIf ($DeviceSerial) {
            # Set the URI to filter on the serial number
            $deviceUri = "$managedDevicesUri/`?`$filter=serialNumber eq '$DeviceSerial'"
        }

        # Connect MgGraph
        Connect-MgGraph -Scopes DeviceManagementConfiguration.ReadWrite.All,DeviceManagementManagedDevices.PrivilegedOperations.All -NoWelcome

        # Get the device information and set the wipe Uri
        $deviceInfo = Invoke-MgGraphRequest -Method GET -Uri $deviceUri
        If ($null -eq $DeviceId) {
            $DeviceId = $deviceInfo.Value.Id
        }
        
        # Check if more than one result was returned; if so, throw an error
        If ($deviceInfo.'@odata.Count' -gt 1) { 
            throw "More than one device record returned. If utilizing the DeviceName parameter, try the Serial, IMEI, or DeviceID instead."
        }

        # Set the wipe URI
        $wipeUri = "$managedDevicesUri('$($deviceInfo.Value.Id)')/wipe"

        If ($OS -eq 'Windows') {
            # Wipe the device
            Invoke-MgGraphRequest -Method POST -Uri $wipeUri
            Write-Host "Wipe initiated on: " -NoNewline
            Write-Host $deviceInfo.Value.deviceName -ForegroundColor Red
        } ElseIf ($OS -eq 'Android') {
            # Wipe the device
            Invoke-MgGraphRequest -Method POST -Uri $wipeUri
            Write-Host "Wipe initiated on: " -NoNewline
            Write-Host $deviceInfo.Value.deviceName -ForegroundColor Red
        } ElseIf ($OS -eq 'MacOs') {
            # Get the ActivationLockBypassCode
            $albCode = (Invoke-MgGraphRequest -Method GET -Uri "$managedDevicesUri('$($deviceInfo.Value.Id)')/`?`$select=activationLockBypassCode")['activationLockBypassCode']
            # Write-Host on the fetched code
            Write-Host "The ActivateLock Bypass Code is: " -NoNewline
            Write-Host $albCode -ForegroundColor Red
            # Also, export the code to a local file
            Export-ALBCode
            # Kick off an activation lock bypass (is there a way to validate this?)
            Invoke-MgGraphRequest -Method POST -Uri "$managedDevicesUri/$($deviceInfo.Value.Id)/microsoft.graph.bypassActivationLock"
            # Wipe the device
            Invoke-MgGraphRequest -Method POST -Uri $wipeUri
            Write-Host "Wipe initiated on: " -NoNewline
            Write-Host $deviceInfo.Value.deviceName -ForegroundColor Red
        } ElseIf ($OS -eq 'iOS') {
            # Get the ActivationLockBypassCode
            $albCode = (Invoke-MgGraphRequest -Method GET -Uri "$managedDevicesUri('$($deviceInfo.Value.Id)')/`?`$select=activationLockBypassCode")['activationLockBypassCode']
            # Write-Host on the fetched code
            Write-Host "The ActivateLock Bypass Code is: " -NoNewline
            Write-Host $albCode -ForegroundColor Red
            # Also, export the code to a local file
            Export-ALBCode
            # Kick off an activation lock bypass (is there a way to validate this?)
            Invoke-MgGraphRequest -Method POST -Uri "$managedDevicesUri/$($deviceInfo.Value.Id)/microsoft.graph.bypassActivationLock"
            # Wipe the device
            Invoke-MgGraphRequest -Method POST -Uri $wipeUri
            Write-Host "Wipe initiated on: " -NoNewline
            Write-Host $deviceInfo.Value.deviceName -ForegroundColor Red
        }

    } End {
        # Any cleanup code here
    }
}