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
Write-Host "(1/9) Install PowerShell modules ..." -ForegroundColor Green

Install-Module -Name Az -Scope AllUsers -Repository PSGallery -Force -AllowClobber
Install-Module -Name AzureAD -Scope AllUsers -Repository PSGallery -Force -AllowClobber

# Check whether the tenant is valid or not
Write-Host "(2/9) Checking tenant availability ..." -ForegroundColor Green

$uri = "https://o365.rocks/home/check"
$body = @{ name = $TenantName } | ConvertTo-Json
$headers = @{ "Content-Type" = "application/json" }
$response = Invoke-RestMethod -Method POST -Uri $uri -Headers $headers -Body $body

if ($response.available -eq $true) {
    Write-Host "The tenant, $TenantName, doesn't exist" -ForegroundColor Red -BackgroundColor Yellow

    return
}

# Login to AzureAD
Write-Host "(3/9) Logging into Azure AD ..." -ForegroundColor Green

$adminUpn = "$AdminUsername@$TenantName.onmicrosoft.com"
$adminPW = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$adminCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($adminUpn, $adminPW)

$connected = Connect-AzureAD -Credential $adminCredential

# Add user accounts
Write-Host "(4/9) Creating user accounts ..." -ForegroundColor Green

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

# Assign roles to user
Write-Host "(5/9) Assigning user roles ..." -ForegroundColor Green

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

# Assign licence to user
Write-Host "(6/9) Assigning licenses ..." -ForegroundColor Green

$sku = Get-AzureADSubscribedSku

$license = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
$license.SkuId = $sku.SkuId

$licensesToAssign = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
$licensesToAssign.AddLicenses = $license

$users | ForEach-Object {
    $assigned = Set-AzureADUserLicense -ObjectId $_.ObjectId -AssignedLicenses $licensesToAssign
}

# Login to Azure
Write-Host "(7/9) Logging into Azure ..." -ForegroundColor Green

$connected = Connect-AzAccount -Credential $adminCredential

# Register resource providers
Write-Host "(8/9) Registering resource providers ..." -ForegroundColor Green

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

# Assign Azure roles to user
Write-Host "(9/9) Assigning Azure roles ..." -ForegroundColor Green

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

# Initialise Power Apps Dataverse
Write-Host "`r`n"
Write-Host "-=-=-=- Initialising Power Apps Dataverse -=-=-=-" -ForegroundColor Blue -BackgroundColor White
Write-Host "`r`n"

powershell ./Set-PowerAppDataverse.ps1 -TenantName $TenantName -AdminUsername $AdminUsername -AdminPassword $AdminPassword
