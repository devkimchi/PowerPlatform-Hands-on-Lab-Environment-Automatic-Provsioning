# PowerPlatform Hands-on-Lab Environment Automatic Provsioning #

This provides sample PowerShell scripts to automatically provision Microsoft 365 and Azure environments for Power Platform hands-on-labs.


## More Readings ##

* 한국어: 파워 플랫폼 핸즈온랩 자동 환경 설정
* English: Automatic Provisioning Power Platform Hands-on-Labs Environment


## Getting Started ##

### 1. Trial Tenant for Microsoft 365 ###

* Open a trial tenant for Microsoft 365: [http://aka.ms/Office365E5Trial](http://aka.ms/Office365E5Trial)
  * Use the username, "`admin`" (or something else you like), and a password of your choice.
  * Use a tenant name of your choice.
  * **DON'T need a credit card.**


### 2. Trial Subscription for Azure ###

* Open a trial subscription for Azure: [https://portal.azure.com](https://portal.azure.com)
  * Use the admin account of the Microsoft 365 tenant created above.
  * **DO need a credit card for the verification purpose.**


### 3. Environment Provisioning ###

* Run the following PowerShell script. Make sure this is for **Windows only**.

    ```powershell
    $username = "admin"
    $password = "<password_of_your_choice>"
    $tenantName = "<tenant_name_of_your_choice>"

    ./AzureAD/Set-Environment.ps1 `
        -AdminUsername $username `
        -AdminPassword $password `
        -TenantName $tenantName
    ```
