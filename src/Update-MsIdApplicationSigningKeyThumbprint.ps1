<#
.SYNOPSIS
    Update a Service Princpal's preferredTokenSigningKeyThumbprint to the specified certificate thumbprint

.DESCRIPTION
    Update a Service Princpal's preferredTokenSigningKeyThumbprint to the specified certificate thumbprint
    For more information on Microsoft Identity platorm signing key rollover see https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-signing-key-rollover

.EXAMPLE
    PS > Update-MsIdApplicationSigningKeyThumbprint -ApplicationId <ApplicationId> -KeyThumbprint <Thumbprint>

    Update Application's preferred signing key to the specified thumbprint

.EXAMPLE
    PS > Update-MsIdApplicationSigningKeyThumbprint -ApplicationId <ApplicationId> -Default
    
    Update Application's preferred signing key to default value null

.EXAMPLE
    PS > Get-MsIdSigningKeyThumbprint -Latest | Update-MsIdApplicationSigningKeyThumbprint -ApplicationId <ApplicationId>

    Get the latest signing key thumbprint and set it as the perferred signing key on the application

#>
function Update-MsIdApplicationSigningKeyThumbprint {
    [CmdletBinding()]
    param (
        # Tenant ID
        $Tenant = "common",

        # Application ID
        [parameter(mandatory = $true)]
        [string]$ApplicationId,

        # Thumbprint of certificate
        [parameter(ValueFromPipeline = $true)]
        [string]$KeyThumbprint,

        # Return preferredTokenSigningKeyThumbprint to default value
        [parameter(parametersetname = "Default")]
        [switch]$Default
    )

    begin {
        ## Initialize Critical Dependencies
        $CriticalError = $null
        if (!(Test-MgCommandPrerequisites 'Get-MgServicePrincipal', 'Update-MgServicePrincipal' -MinimumVersion 1.9.2 -ErrorVariable CriticalError)) { return }
    }

    process {
        if ($CriticalError) { return }

        if ($Default) { 
            Write-Verbose "Default flag set. preferredTokenSigningKeyThumbprint will be set to null "
            $KeyThumbprint = $null 
        }

        if ($null -ne $KeyThumbprint) {
            $KeyThumbprint = $KeyThumbprint.Replace(" ", "").ToLower()
        }

        $body = @{preferredTokenSigningKeyThumbprint = $KeyThumbprint } | ConvertTo-Json 
        $body = $body.replace('""','null')

        Write-Verbose "Retrieving Service Principal"
        $sp = Get-MgServicePrincipal -Filter "appId eq '$ApplicationId'"

        if ($null -ne $sp) {
            Write-Verbose "Service Principal found: $($sp.DisplayName)"
            Write-Verbose "Updating Service Principal preferredTokenSigningKeyThumbprint"
            Invoke-MgGraphRequest -Method "PATCH" -Uri "https://graph.microsoft.com/v1.0/servicePrincipals/$($sp.id)" -Body $body
        }
        else {
            Write-Error "Service principal was not found - Please check the Client (Application) ID"
        }
    }
}