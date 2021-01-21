param([Parameter(Mandatory=$true)][string]$dpsScopeId, [Parameter(Mandatory=$true)][string]$edgeDeviceName)

Write-Host "Invoked sample: .\ProvisionEdgeVM.ps1 <DSP ScopeID> <IoT Edge Device Name>"

## Prepare
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
. .\certificates\ca-certs.ps1
Test-CACertsPrerequisites

Write-Host "Using $dpsScopeId as DPS Scope ID"
Write-Host "Using $edgeDeviceName as IoT Edge Device (the VM provisioned will be iot-playground-$edgeDeviceName-vm)"
Write-Host "Certifificates will be generated in the folder .\certificates\edgeVms\$edgeDeviceName"

$rsg="iot-playground-rsg"
$storageAccount="iotplaygroundsta"
$adminUserName="azureiotadmin"

New-CACertsEdgeDeviceIdentity "$edgeDeviceName" "azure-iot-test-only.root.ca"
New-CACertsEdgeDevice "$edgeDeviceName-CA"
# New-CACertsDevice "Upstream1_$edgeDeviceName"
# New-CACertsDevice "Upstream2_$edgeDeviceName"
# New-CACertsDevice "Upstream3_$edgeDeviceName"
# New-CACertsDevice "Upstream4_$edgeDeviceName"

#Regorganize Certs
New-Item -Path .\certificates\edgeVms\$edgeDeviceName -Force -ItemType Directory
Move-Item -Path .\certificates\certs\*$edgeDeviceName* -Destination .\certificates\edgeVms\$edgeDeviceName -Exclude .\certificates\$edgeDeviceName -Force
Move-Item -Path .\certificates\private\*$edgeDeviceName* -Destination .\certificates\edgeVms\$edgeDeviceName -Exclude .\certificates\$edgeDeviceName -Force
Copy-Item -Path .\certificates\certs\azure-iot-test-only.root.ca.cert.pem -Destination .\certificates\edgeVms\$edgeDeviceName -Force

# Upload Certs to Storage Account
az storage blob upload-batch --account-name $storageAccount --destination certificates --source ".\certificates\edgeVms\$edgeDeviceName" --destination-path "$edgeDeviceName"

$expiry=((Get-Date).AddMinutes(30).ToString("yyyy-MM-ddTHH:mm:ssZ"))
$sas=(az storage container generate-sas --account-name $storageAccount --name certificates --permissions rl --expiry $expiry -o tsv)

$certsStorageSasUrl="""https://$storageAccount.blob.core.windows.net/certificates/$edgeDeviceName/*?$sas"""
$rsaPubContent=(Get-Content -Path $HOME/.ssh/iotedge-vm-iot-playground.pub)

Write-Host ""
Write-Host "Executing VM Provisioning. Running command: "
Write-Host "az deployment group create --resource-group $rsg --template-file .\iotedge-vm-deploy\edgeDeploy.json --parameters edgeDeviceName="$edgeDeviceName" certsStorageSasUrl="$certsStorageSasUrl" adminUsername="$adminUserName" dpsScopeId="$dpsScopeId" adminPasswordOrKey="$rsaPubContent""
Write-Host ""
az deployment group create --resource-group $rsg --template-file .\iotedge-vm-deploy\edgeDeploy.json --parameters edgeDeviceName="$edgeDeviceName" certsStorageSasUrl="$certsStorageSasUrl" adminUsername="$adminUserName" dpsScopeId="$dpsScopeId" adminPasswordOrKey="$rsaPubContent"
az vm auto-shutdown --resource-group $rsg --name iot-playground-$EdgeDeviceName-vm --time 1930 

