param([Parameter(Mandatory=$true)][string]$edgeDeviceName)

## Prepare
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
. .\certificates\ca-certs.ps1
Test-CACertsPrerequisites

Write-Host "Using $edgeDeviceName as IoT Edge Device (the VM configured will be iot-playground-$edgeDeviceName-vm)"
Write-Host "Certifificates will be generated in the folder .\certificates\edgeVms\$edgeDeviceName\upstream"

$rsg="iot-playground-rsg"
$iotHub="iot-playground-devices-hub"
$storageAccount="iotplaygroundsta"
$adminUserName="azureiotadmin"

$ups1DeviceName="$edgeDeviceName-ups1"
$ups2DeviceName="$edgeDeviceName-ups2"
$ups3DeviceName="$edgeDeviceName-ups3"
$ups4DeviceName="$edgeDeviceName-ups4"


New-CACertsDevice $ups1DeviceName
New-CACertsDevice $ups2DeviceName
New-CACertsDevice $ups3DeviceName
New-CACertsDevice $ups4DeviceName

#Regorganize Certs
New-Item -Path .\certificates\edgeVms\$edgeDeviceName\upstreamCerts -Force -ItemType Directory
Move-Item -Path .\certificates\certs\*$edgeDeviceName* -Destination .\certificates\edgeVms\$edgeDeviceName\upstreamCerts -Exclude .\certificates\$edgeDeviceName -Force
Move-Item -Path .\certificates\private\*$edgeDeviceName* -Destination .\certificates\edgeVms\$edgeDeviceName\upstreamCerts -Exclude .\certificates\$edgeDeviceName -Force
Copy-Item -Path .\certificates\certs\azure-iot-test-only.root.ca.cert.pem -Destination .\certificates\edgeVms\$edgeDeviceName\upstreamCerts -Force ##TODO: is required?

# Upload Certs to Storage Account
# az storage blob upload-batch --account-name $storageAccount --destination certificates --source ".\certificates\edgeVms\$edgeDeviceName\upstream" --destination-path "$edgeDeviceName\upstream"

# $expiry=((Get-Date).AddMinutes(30).ToString("yyyy-MM-ddTHH:mm:ssZ"))
# $sas=(az storage container generate-sas --account-name $storageAccount --name certificates --permissions rl --expiry $expiry -o tsv)
# $certsStorageSasUrl="""https://$storageAccount.blob.core.windows.net/certificates/$edgeDeviceName/*?$sas"""
# $rsaPubContent=(Get-Content -Path $HOME/.ssh/iotedge-vm-iot-playground.pub)


$deviceExists=(az iot hub device-identity show --device-id $edgeDeviceName --hub-name $iotHub)
if($deviceExists){
    az iot hub device-identity create -n $iotHub -d "$ups1DeviceName" --am x509_ca 
    az iot hub device-identity parent set -d "$ups1DeviceName" --pd "$edgeDeviceName" -n $iotHub --force

    az iot hub device-identity create -n $iotHub -d "$ups2DeviceName" --am x509_ca 
    az iot hub device-identity parent set -d "$ups2DeviceName" --pd "$edgeDeviceName" -n $iotHub --force

    az iot hub device-identity create -n $iotHub -d "$ups3DeviceName" --am x509_ca 
    az iot hub device-identity parent set -d "$ups3DeviceName" --pd "$edgeDeviceName" -n $iotHub --force

    az iot hub device-identity create -n $iotHub -d "$ups4DeviceName" --am x509_ca 
    az iot hub device-identity parent set -d "$ups4DeviceName" --pd "$edgeDeviceName" -n $iotHub --force
}

scp -i $HOME/.ssh/iotedge-vm-iot-playground -r ".\certificates\edgeVms\$edgeDeviceName\upstreamCerts" "$adminUserName@iot-playground-$edgeDeviceName.westeurope.cloudapp.azure.com:~/"

