<#

In progress

.SYNOPSIS
    Validate MP
.DESCRIPTION
    Validate the HTTPS-Only MP with the machine's certificate thumbprint.
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
Function Test-MPCert {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)]
        [string]
        $Thumbprint,
        [Parameter(Mandatory = $True)]
        [string]
        $MPFQDN
    )

    # Grab the certificate in question
    $Certificate = Get-ChildItem -Path "Cert:\LocalMachine\My\$Thumbprint"

    # Invoke the webrequest to the MP
    Invoke-WebRequest -Uri "https://$MPFQDN/sms_mp/.sms_aut?mplist" -Certificate $Certificate -UseBasicParsing | Select-Object -ExpandProperty Content
}