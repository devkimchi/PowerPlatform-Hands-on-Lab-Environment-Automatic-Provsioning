Param(
    [string]       [Parameter(Mandatory = $true)]  $AdminUsername,
    [securestring] [Parameter(Mandatory = $true)]  $AdminPassword,
    [string]       [Parameter(Mandatory = $true)]  $TenantName
)

# Install modules
Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Scope AllUsers -Repository PSGallery -Force -AllowClobber
Install-Module -Name Microsoft.PowerApps.PowerShell -Scope AllUsers -Repository PSGallery -Force -AllowClobber

# Login to Power Apps
Write-Host "(1/2) Logging into Power Apps ..." -ForegroundColor Green

$adminUpn = "$AdminUsername@$TenantName.onmicrosoft.com"
$adminPW = $AdminPassword

$connected = Add-PowerAppsAccount -Username $adminUpn -Password $adminPW

# Initialise Dataverse to the default environment
Write-Host "(2/2) Initialising Dataverse ..." -ForegroundColor Green

$paenv = Get-AdminPowerAppEnvironment -Default
if ($paenv.CommonDataServiceDatabaseProvisioningState -eq "Succeeded") {
    Write-Host "Dataverse in the default environment has already been initialised" -ForegroundColor Red

    return
}

$currency = Get-AdminPowerAppCdsDatabaseCurrencies `
    -LocationName $paenv.Location | Where-Object {
        $_.IsTenantDefaultCurrency -eq $true
    }

$language = Get-AdminPowerAppCdsDatabaseLanguages `
    -LocationName $paenv.Location | Where-Object {
        $_.IsTenantDefaultLanguage -eq $true
    }

$activated = New-AdminPowerAppCdsDatabase `
    -EnvironmentName $paenv.EnvironmentName `
    -CurrencyName $currency.CurrencyName `
    -LanguageName $language.LanguageName
