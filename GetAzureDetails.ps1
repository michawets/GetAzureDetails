param (
    [Parameter(Mandatory = $true)]
    [string]$sastoken
)

#Requires -Module Az.Accounts

try {
    Stop-Transcript
} 
catch {}

$ErrorActionPreference = "Stop"
$ScriptLocation = "c:\temp"

if ($null -eq (Get-Item -Path $ScriptLocation -ErrorAction SilentlyContinue)) {
    $dummy = New-Item -Path $ScriptLocation -ItemType Directory -Force
}
$logfileName = ("GetAzureDetails_{0}.log" -f ((Get-Date).ToString("o").Replace(":", "_")))
$logFile = ("{0}\{1}" -f $ScriptLocation, $logfileName)
Start-Transcript -Path $logFile
Write-Host ("Started at {0}" -f (Get-Date).ToString("o")) -ForegroundColor Cyan

$fullAzureSubscriptionDetailsList = @()
$fullAzureSpecificResourcesList = @()
$fullAzureVmResourcesList = @()
$fullAzureDiskResourcesList = @()
$fullAzureSaResourcesList = @()

if ($null -eq (Get-AzContext)) {
    Write-Host "Please sign in into Azure" -ForegroundColor Cyan
    Connect-AzAccount
}
Write-Host "--> Getting the Azure Subscription list" -ForegroundColor Cyan
$azureSubscriptionList = Get-AzSubscription
#Write-Host ("Subscription list: '{0}'" -f ($azureSubscriptionList | ConvertTo-Json -Compress))

foreach ($azureSubscription in $azureSubscriptionList) {
    Write-Host ("--> Switching to Subscription '{0}' - '{1}'" -f $azureSubscription.Name, $azureSubscription.Id) -ForegroundColor Cyan
    $dummy = Select-AzSubscription $azureSubscription.Id

    $fullAzureResourceGroupDetailsList = @()

    Write-Host "--> Getting the Resource Group list" -ForegroundColor Cyan
    $resourceGroupList = Get-AzResourceGroup
    #Write-Host ("Resource Group list: '{0}'" -f ($resourceGroupList | ConvertTo-Json -Compress))

    foreach ($resourceGroup in $resourceGroupList) {
        Write-Host ("--> Getting the Resources in '{0}'" -f $resourceGroup.ResourceGroupName) -ForegroundColor Cyan
        $resourceGroupName = $resourceGroup.ResourceGroupName
        $resourceList = Get-AzResource -ODataQuery "`$filter=resourcegroup eq '$resourceGroupName'" -ExpandProperties
        #Write-Host ("Resource list: '{0}'" -f ($resourceList | ConvertTo-Json -Compress))
        $fullAzureResourceDetailsList = [ordered]@{
            "ResourceGroupName" = $resourceGroupName
            "Resources"         = $resourceList
        }
        $fullAzureResourceGroupDetailsList += New-Object PSObject -Property $fullAzureResourceDetailsList

        foreach ($resource in $resourceList) {
            switch ($resource.Type) {
                "Microsoft.Compute/virtualMachines" {
                    Write-Host ("--> Getting VM Details from '{0}'" -f $resource.ResourceName) -ForegroundColor Cyan
                    $vm = Get-AzVM -ResourceGroupName $resourceGroup.ResourceGroupName -Name $resource.ResourceName -Status
                    #Write-Host ("VM '{0}': {1}" -f $resource.ResourceName, ($vm | ConvertTo-Json -Compress))
                    $vmDetails = [ordered]@{
                        "VMName"  = $resource.ResourceName
                        "Details" = $vm
                    }
                    $fullAzureVmResourcesList += New-Object PSObject -Property $vmDetails
                }
                "Microsoft.Compute/disks" {
                    Write-Host ("--> Getting Disk Details from '{0}'" -f $resource.ResourceName) -ForegroundColor Cyan
                    $disk = Get-AzDisk -ResourceGroupName $resourceGroup.ResourceGroupName -DiskName $resource.ResourceName
                    #Write-Host ("Disk '{0}': {1}" -f $resource.ResourceName, ($disk | ConvertTo-Json -Compress))
                    $diskDetails = [ordered]@{
                        "DiskName" = $resource.ResourceName
                        "Details"  = $disk
                    }
                    $fullAzureDiskResourcesList += New-Object PSObject -Property $diskDetails
                }
                "Microsoft.Storage/storageAccounts" {
                    Write-Host ("--> Getting StorageAccount Details from '{0}'" -f $resource.ResourceName) -ForegroundColor Cyan
                    $sa = Get-AzStorageAccount -ResourceGroupName $resourceGroup.ResourceGroupName -Name $resource.ResourceName
                    #Write-Host ("StorageAccount '{0}': {1}" -f $resource.ResourceName, ($sa | ConvertTo-Json -Compress))
                    $saDetails = [ordered]@{
                        "StorageAccountName" = $resource.ResourceName
                        "Details"            = $sa
                    }
                    $fullAzureSaResourcesList += New-Object PSObject -Property $saDetails
                }
                Default {}
            }
        }
    }

    $fullAzureSubscriptionDetails = [ordered]@{
        "SubscriptionName" = $azureSubscription.Name
        "ResourceGroups"   = $fullAzureResourceGroupDetailsList
    }

    $fullAzureSubscriptionDetailsList += New-Object PSObject -Property $fullAzureSubscriptionDetails
}

$fullAzureSpecificResourcesList += New-Object PSObject -Property @{
    "VMs"             = $fullAzureVmResourcesList
    "Disks"           = $fullAzureDiskResourcesList
    "StorageAccounts" = $fullAzureSaResourcesList
}

Write-Host "--> Output Specific Resources" -ForegroundColor Cyan
Write-Host ($fullAzureSpecificResourcesList | ConvertTo-Json -Depth 5 -Compress)
Write-Host "--> Output full trace" -ForegroundColor Cyan
Write-Host ($fullAzureSubscriptionDetailsList | ConvertTo-Json -Depth 5 -Compress)

Stop-Transcript

Write-Host "uploading to Storage Account"
$uri = ("https://cacxngetazuredetailssa.blob.core.windows.net/azurelogs/{0}?{1}" -f $logfileName, $sastoken)
$headers = @{
    'x-ms-blob-type' = 'BlockBlob'
}
Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -InFile $logFile

Write-Host "All Done..." -ForegroundColor Green