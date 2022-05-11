# Howto

These scripts can help you create an overview of your Azure Subscription.<br/>
It will then upload the info to us.

The script will

* Authenticate to Azure
* Loop through your Azure Subscriptions
* Loop through your Azure Resource Groups
* Get details on the Resources in your Resource Groups
* Upload the info to our storage account.

## Requirements

You need to have the Azure Powershell Modules on your device.<br/>
This can be easily installed on your device using the following cmdlet:

```powershell
Install-Module -Name Az
```

## Execution

You need to run the script in a Powershell window.<br/>
The script will ask for a SAS Token. To obtain a SAS Token, contact your Support Engineer.

```powershell
New-Item -ItemType Directory -Path "C:\Temp" -Force
Set-Location -Path "C:\Temp"
$Uri = "https://raw.githubusercontent.com/michawets/GetAzureDetails/main/GetAzureDetails.ps1"
# Download the script
Invoke-WebRequest -Uri $Uri -OutFile ".\GetAzureDetails.ps1"
# Run the script
& '.\GetAzureDetails.ps1'
```
