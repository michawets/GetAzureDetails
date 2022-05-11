# Howto

These scripts can help you create an overview of your Azure Subscription.
It will then upload the info to us.

The script will

* Authenticate to Azure
* Loop through your Azure Subscriptions
* Loop through your Azure Resource Groups
* Get details on the Resources in your Resource Groups
* Upload the info to our storage account.

## You need to run the script in a Powershell window

```powershell
New-Item -ItemType Directory -Path "C:\Temp" -Force
Set-Location -Path "C:\Temp"
$Uri = "https://raw.githubusercontent.com/michawets/GetAzureDetails/main/GetAzureDetails.ps1"
# Download the script
Invoke-WebRequest -Uri $Uri -OutFile ".\GetAzureDetails.ps1"
# Run the script
& '.\GetAzureDetails.ps1'
```
