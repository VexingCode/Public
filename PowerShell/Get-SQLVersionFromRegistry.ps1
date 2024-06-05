Function Get-SQLVersionFromRegistry {
    $instances = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances
    ForEach ($instance in $instances) {
        $verInst = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$instance
        $properties = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$verInst\Setup"
        $edition = $properties.Edition
        $version = $properties.Version
        $patchLevel = $properties.PatchLevel
        Write-Host "Instance: $verInst, Edition: $edition, Version: $version, Patch Level: $patchLevel"
    }
}