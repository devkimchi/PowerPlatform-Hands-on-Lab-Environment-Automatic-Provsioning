Param(
    [string] [Parameter(Mandatory = $true)]  $AdminUsername,
    [string] [Parameter(Mandatory = $true)]  $AdminPassword,
    [string] [Parameter(Mandatory = $true)]  $TenantName
)

# Install modules
Write-Host "(1/3) Install PowerShell modules ..." -ForegroundColor Green

Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Scope AllUsers -Repository PSGallery -Force -AllowClobber
Install-Module -Name Microsoft.PowerApps.PowerShell -Scope AllUsers -Repository PSGallery -Force -AllowClobber

# Login to Power Apps
Write-Host "(2/3) Logging into Power Apps ..." -ForegroundColor Green

$adminUpn = "$AdminUsername@$TenantName.onmicrosoft.com"
$adminPW = ConvertTo-SecureString $AdminPassword -AsPlainText -Force

$connected = Add-PowerAppsAccount -Username $adminUpn -Password $adminPW

# Initialise Dataverse to the default environment
Write-Host "(3/3) Initialising Dataverse ..." -ForegroundColor Green

$paenv = Get-AdminPowerAppEnvironment -Default
if ($paenv.CommonDataServiceDatabaseProvisioningState -eq "Succeeded") {
    Write-Host "Dataverse in the default environment has already been initialised" -ForegroundColor Red -BackgroundColor Yellow

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

Write-Host "`r`n"
Write-Host "-=-=-=- Initialised Power Apps Dataverse -=-=-=-" -ForegroundColor Blue -BackgroundColor White
Write-Host "`r`n"
