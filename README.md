# PowerPlatform Hands-on-Lab Environment Automatic Provsioning #

This provides sample PowerShell scripts to automatically provision Microsoft 365 and Azure environments for Power Platform hands-on-labs.


## Acknowledgement ##

* The tenant validation process in the PowerShell script uses an HTTP API on [https://o365.rocks/](https://o365.rocks/).


## More Readings ##

* 한국어: 파워 플랫폼 핸즈온랩 자동 환경 설정
* English: Automatic Provisioning Power Platform Hands-on-Labs Environment


## Prerequisites ##

* **Windows (x64) only**
* More details about the environment, refer to [this document](https://docs.microsoft.com/microsoft-365/enterprise/connect-to-microsoft-365-powershell?WT.mc_id=github-0000-juyoo#what-do-you-need-to-know-before-you-begin).


## Getting Started ##

### 1. Trial Tenant for Microsoft 365 ###

* Open a trial tenant for Microsoft 365: [http://aka.ms/Office365E5Trial](http://aka.ms/Office365E5Trial)
  * Use the username, "`admin`" (or something else you like), and a password of your choice.
  * Use a tenant name of your choice.
  * **DON'T need a credit card.**


### 2. Trial Subscription for Azure ###

* Open a trial subscription for Azure: [https://portal.azure.com](https://portal.azure.com?WT.mc_id=github-0000-juyoo)
  * Use the admin account of the Microsoft 365 tenant created above.
  * **DO need a credit card for the verification purpose.**


### 3. Environment Provisioning ###

* Run the following PowerShell script. Make sure this is for **Windows only**.
* Note that the `$password` is a plain text format. It will be encrypted within the PowerShell script.

    ```powershell
    $username = "admin"
    $password = "<password_of_your_choice>"
    $tenantName = "<tenant_name_of_your_choice>"

    ./AzureAD/Set-Environment.ps1 `
        -AdminUsername $username `
        -AdminPassword $password `
        -TenantName $tenantName
    ```


## Contribution ##

Your contributions are always welcome! All your work should be done in your forked repository. Once you finish your work, please send us a pull request onto our `main` branch for review.


## License ##

This is released under [MIT License](http://opensource.org/licenses/MIT)

> The MIT License (MIT)
>
> Copyright (c) 2021 [Dev Kimchi](https://devkimchi.com)
> 
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
> 
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
> 
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
