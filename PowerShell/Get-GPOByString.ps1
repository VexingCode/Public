<#
.SYNOPSIS
    Search GPOs for specific string.
.DESCRIPTION
    Searches a certain GPO, or all GPOs, for a specified string. Outputs their name, ID, and links to
    the designated URL.
.EXAMPLE
    PS C:\Windows\System32> Get-GPOByString -SearchString 'InactivityTimeout' -Domain 'contoso.domain.com' -ExportPath 'C:\Temp'
    This example creates an "InactivityTimeout-GPOsearchResults.csv" in "C:\Temp", with all policies containing "InactivityTimeout".

    PS C:\Windows\System32> Get-GPOByString -SearchString 'InactivityTimeout' -Domain 'contoso.domain.com' -ExportPath 'C:\Temp' -Policy 'Some.Policy.Here'
    This example creates an "InactivityTimeout-GPOsearchResults.csv" in "C:\Temp", searching the 'Some.Policy.Here' policy. It will be blank if the setting is not found.
.PARAMETER SearchString
    Use the -SearchString parameter to specify what setting you are looking for. This is a required parameter.
.PARAMETER Domain
    Use the -Domain parameter to specify the domain to search. This is a required parameter.
.PARAMETER Policy
    Use the -Policy parameter to specify an individual policy to search. This is not a required parameter.
.PARAMETER ExportPath
    Use the -ExportPath parameter to specify where you would like to save the file to. Leave off a trailing '\'. This is a required parameter.
.OUTPUTS
    CSV file in the specified directory. Use -Verbose for some progress updates.
.NOTES
    Name:           Get-GPOByString
    Author:         Jason Kuhn, Ahnamataeus Vex
    Version:        1.0.0
    Release Date:   2022-07-15
        Updated:
            Version 1.0.1: 2022-11-29
                Changed the name of the output file. Prefixed "GPOSearch-Str-" so it would be easier to find/get grouped together.
#>

Function Get-GPOByString {
  [CmdletBinding()]
  param (
      [Parameter(Mandatory=$true)]
      [string]
      $SearchString,
      [Parameter(Mandatory=$true)]
      [string]
      $Domain,
      [Parameter()]
      [string]
      $Policy,
      [Parameter(Mandatory=$true)]
      [string]
      $ExportPath
  )

  # Grab the nearest DC
  $NearestDC = (Get-ADDomainController -Discover -NextClosestSite).Name

  # Set the CSV location and name
  $csv = "$ExportPath\GPOSearch-Str-$SearchString.csv"

  # Create a CSV file with the search string in the file name, containing Name and ID of the GPO
  If (Test-Path $ExportPath) {
    Add-Content -Path $csv  -Value '"DisplayName","ID","Links"'
  }
  Else {
    New-Item -Path $ExportPath
    Add-Content -Path $csv  -Value '"DisplayName","ID","Links"'
  }

  # If $Policy is specified, then query on that, else query all
  If ($Policy) {
    $GPOs = Get-GPO -Name $Policy -Domain $Domain -Server $NearestDC
  }
  Else {
    $GPOs = Get-GPO -All -Domain $Domain -Server $NearestDC | Sort-Object DisplayName
  }

  # Go through each Object and check its XML against $SearchString
  ForEach ($GPO in $GPOs) {
    Write-Verbose "Searching $($GPO.DisplayName)."

    # Get Current GPO Report (XML)
    $CurrentGPOReport = Get-GPOReport -Name $GPO.DisplayName -ReportType Xml -Domain $Domain -Server $NearestDC

    If ($CurrentGPOReport -match $SearchString) {
	    Write-Verbose "Found ""$($SearchString)"" in GPO: $($GPO.DisplayName)"
      
      # Generate the XML to grab the links
      [xml]$xmlReport = Get-GPOReport -Name $GPO.DisplayName -ReportType Xml -Domain $Domain -Server $NearestDC

      # Write the links to a var, concatenating the strings with a '; ' separator
      $links = $xmlReport.DocumentElement.LinksTo.SOMPath -Join '; '

      # Write search results to the csv file
      Write-Verbose "Writing data to the CSV."
      Add-Content -Path $csv -Value "$($GPO.DisplayName),$($GPO.ID),$links"
    }
  }
}