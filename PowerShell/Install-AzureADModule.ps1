Function Install-AzureADModule {
    Write-Verbose 'Grabbing the version of AzureAD from the gallery...'
    $GalleryModuleVersion = (Find-Module AzureAD).Version
    Write-Verbose 'Gallery version is:'
    Write-Verbose $GalleryModuleVersion
    Write-Verbose 'Grabbing the version of AzureAD that is installed (if any)...'
    $InstalledModuleVersion = (Get-InstalledModule AzureAD -ErrorAction SilentlyContinue).Version
    If ($null -eq $InstalledModuleVersion) {
        $InstalledModuleVersion = 'Not installed.'
    }
    Write-Verbose 'Installed version is:'
    Write-Verbose $InstalledModuleVersion
    Write-Verbose 'Comparing the two to see if the gallery is newer...'
    If (!($InstalledModuleVersion -ge $GalleryModuleVersion)) {
        Write-Verbose 'Gallery version is newer, or its not installed.'
        Write-Verbose 'Installing the AzureAD module.'
        Install-Module AzureAD -Force -AllowClobber
        Write-Verbose 'Importing the AzureAD module...'
        Import-Module AzureAD
        Write-Verbose 'Connecting to AzureAD. Please ensure you are using a privileged account.'
        Connect-AzureAD
    }
    Else {
        Write-Verbose 'AzureAD module is current.'
        Try {
            $aadConnectionCheck = Get-AzureADTenantDetail
            $tenant = $aadConnectionCheck.DisplayName
            Write-Verbose "AzureAD already connected to: $tenant"
            Write-Verbose "Skipping connection step."
        } 
        Catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException] {
            Write-Verbose 'Connecting to AzureAD. Please ensure you are using a privileged account.'
            Connect-AzureAD
        }
    }
}