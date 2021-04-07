Param(
    [string] [Parameter(Mandatory = $true)]  $AdminUsername,
    [string] [Parameter(Mandatory = $true)]  $AdminPassword,
    [string] [Parameter(Mandatory = $true)]  $TenantName,
    [int]    [Parameter(Mandatory = $false)] $NumberOfUsers = 24,
    [int]    [Parameter(Mandatory = $false)] $UserStartingIndex = 1,
    [string] [Parameter(Mandatory = $false)] $UsageLocation = "KR",
    [string] [Parameter(Mandatory = $false)] $ResourceLocation = "koreacentral",
    [switch]                                 $AddPowerBI,
    [switch]                                 $RegisterLogicApp,
    [switch]                                 $RegisterApiManagement,
    [switch]                                 $RegisterCosmosDB
)

# Install modules
Write-Host "(1/11) Install PowerShell modules ..." -ForegroundColor Green

Install-Module -Name Az -Scope AllUsers -Repository PSGallery -Force -AllowClobber
Install-Module -Name AzureAD -Scope AllUsers -Repository PSGallery -Force -AllowClobber
Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Scope AllUsers -Repository PSGallery -Force -AllowClobber
Install-Module -Name Microsoft.PowerApps.PowerShell -Scope AllUsers -Repository PSGallery -Force -AllowClobber

Write-Host "-=-=-=- PowerShell modules installed -=-=-=-" -ForegroundColor Blue -BackgroundColor White
Write-Host "`r`n"

# Check whether the tenant is valid or not
Write-Host "(2/11) Validating tenant ..." -ForegroundColor Green

$uri = "https://o365.rocks/home/check"
$body = @{ name = $TenantName } | ConvertTo-Json
$headers = @{ "Content-Type" = "application/json" }
$response = Invoke-RestMethod -Method POST -Uri $uri -Headers $headers -Body $body

if ($response.available -eq $true) {
    Write-Host "The tenant, $TenantName, doesn't exist" -ForegroundColor Red -BackgroundColor Yellow

    return
}

Write-Host "-=-=-=- Tenant validated -=-=-=-" -ForegroundColor Blue -BackgroundColor White
Write-Host "`r`n"

# Login to Power Apps
Write-Host "(3/11) Logging into Power Apps ..." -ForegroundColor Green

$adminUpn = "$AdminUsername@$TenantName.onmicrosoft.com"
$adminPW = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$adminCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($adminUpn, $adminPW)

$connected = Add-PowerAppsAccount -Username $adminUpn -Password $adminPW

Write-Host "-=-=-=- Power Apps logged in -=-=-=-" -ForegroundColor Blue -BackgroundColor White
Write-Host "`r`n"

# Initialise Microsoft Dataverse to the default environment
Write-Host "(4/11) Initialising Microsoft Dataverse ..." -ForegroundColor Green

$paenv = Get-AdminPowerAppEnvironment -Default
if ($paenv.CommonDataServiceDatabaseProvisioningState -eq "Succeeded") {
    Write-Host "Dataverse in the default environment has already been initialised" -ForegroundColor Red -BackgroundColor Yellow
} else {
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
}

Write-Host "-=-=-=- Microsoft Dataverse initialised -=-=-=-" -ForegroundColor Blue -BackgroundColor White
Write-Host "`r`n"

# Login to AzureAD
Write-Host "(5/11) Logging into Azure AD ..." -ForegroundColor Green

$adminUpn = "$AdminUsername@$TenantName.onmicrosoft.com"
$adminPW = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$adminCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($adminUpn, $adminPW)

$connected = Connect-AzureAD -Credential $adminCredential

Write-Host "-=-=-=- AzureAD logged in -=-=-=-" -ForegroundColor Blue -BackgroundColor White
Write-Host "`r`n"

# Add user accounts
Write-Host "(6/11) Creating user accounts ..." -ForegroundColor Green

$userPWProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$userPWProfile.Password = "UserPa`$`$W0rd!@#`$"
$userPWProfile.EnforceChangePasswordPolicy = $false
$userPWProfile.ForceChangePasswordNextLogin = $false

$start = $UserStartingIndex
$end = $NumberOfUsers + $UserStartingIndex -1

$users = @()
($start..$end) | ForEach-Object {
    $user = New-AzureADUser `
        -DisplayName $("PPUser" + $_.ToString("00")) -GivenName $("User" + $_.ToString("00")) -SurName "PP" `
        -UserPrincipalName $("ppuser" + $_.ToString("00") + "@$TenantName.onmicrosoft.com") `
        -UsageLocation $UsageLocation `
        -MailNickName $("ppuser" + $_.ToString("00")) `
        -PasswordProfile $userPWProfile `
        -AccountEnabled $true

    $users += $user
}

Write-Host "-=-=-=- User accounts added -=-=-=-" -ForegroundColor Blue -BackgroundColor White
Write-Host "`r`n"

# Assign roles to user
Write-Host "(7/11) Assigning user roles ..." -ForegroundColor Green

$roleNames = @(
    "Power Platform Administrator"
)
if ($AddPowerBI) {
    $roleNames += "Power BI Administrator"
}

$roles = @()
$roleNames | ForEach-Object {
    $roleName = $_

    $role = Get-AzureADDirectoryRole | Where-Object { $_.DisplayName -eq $roleName }
    if ($role -eq $null) {
        $roleTemplate = Get-AzureADDirectoryRoleTemplate | Where-Object { $_.DisplayName -eq $roleName }
        $enabled = Enable-AzureADDirectoryRole -RoleTemplateId $roleTemplate.ObjectId
    
        $role = Get-AzureADDirectoryRole | Where-Object { $_.DisplayName -eq $roleName }

        $roles += $role
    }
}

$roles | ForEach-Object {
    $role = $_

    $users | ForEach-Object {
        $assigned = Add-AzureADDirectoryRoleMember -ObjectId $role.ObjectId -RefObjectId $_.ObjectId
    }
}

Write-Host "-=-=-=- User roles assigned -=-=-=-" -ForegroundColor Blue -BackgroundColor White
Write-Host "`r`n"

# Assign licence to user
Write-Host "(8/11) Assigning licenses ..." -ForegroundColor Green

$sku = Get-AzureADSubscribedSku

$license = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
$license.SkuId = $sku.SkuId

$licensesToAssign = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
$licensesToAssign.AddLicenses = $license

$users | ForEach-Object {
    $assigned = Set-AzureADUserLicense -ObjectId $_.ObjectId -AssignedLicenses $licensesToAssign
}

Write-Host "-=-=-=- Licenses assigned -=-=-=-" -ForegroundColor Blue -BackgroundColor White
Write-Host "`r`n"

# Login to Azure
Write-Host "(9/11) Logging into Azure ..." -ForegroundColor Green

$connected = Connect-AzAccount -Credential $adminCredential

Write-Host "-=-=-=- Azure logged in -=-=-=-" -ForegroundColor Blue -BackgroundColor White
Write-Host "`r`n"

# Register resource providers
Write-Host "(10/11) Registering resource providers ..." -ForegroundColor Green

$namespaces = @(
    "Microsoft.Storage"
)
if ($RegisterLogicApp) {
    $namespaces += "Microsoft.Logic"
}
if ($RegisterApiManagement) {
    $namespaces += "Microsoft.Network"
    $namespaces += "Microsoft.ApiManagement"
    $namespaces += "Microsoft.Logic"
}
if ($RegisterCosmosDB) {
    $namespaces += "Microsoft.DocumentDB"
}

$namespaces | ForEach-Object {
    $provider = Get-AzResourceProvider -ProviderNamespace $_ | Where-Object { $_.RegistrationState -eq "Registered" }
    if (($provider -eq $null) -or ($provider.Count -eq 0)) {
        $registered = Register-AzResourceProvider -ProviderNamespace $_
    }
}

Write-Host "-=-=-=- Resource providers registered -=-=-=-" -ForegroundColor Blue -BackgroundColor White
Write-Host "`r`n"

# Assign Azure roles to user
Write-Host "(11/11) Assigning Azure roles ..." -ForegroundColor Green

$role = Get-AzRoleDefinition | Where-Object { $_.Name -eq "Contributor" }

$users | ForEach-Object {
    $rg = Get-AzResourceGroup | Where-Object {
        $_.ResourceGroupName -eq $("rg-" + $_.MailNickName)
    }
    if ($rg -eq $null) {
        $rg = New-AzResourceGroup -Name $("rg-" + $_.MailNickName) -Location $ResourceLocation
    }

    $assigned = New-AzRoleAssignment `
        -ObjectId $_.ObjectId `
        -RoleDefinitionId $role.Id `
        -Scope $rg.ResourceId
}

Write-Host "-=-=-=- Azure roles assigned -=-=-=-" -ForegroundColor Blue -BackgroundColor White
Write-Host "`r`n"
