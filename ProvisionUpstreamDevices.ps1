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

$deviceExists=(az iot hub device-identity show --device-id $edgeDeviceName --hub-name $iotHub)
if($deviceExists){
    $upsDeviceExists=(az iot hub device-identity show --device-id $ups1DeviceName --hub-name $iotHub)
    if(!$upsDeviceExists){
        az iot hub device-identity create -n $iotHub -d "$ups1DeviceName" --am x509_ca 
    }
    az iot hub device-identity parent set -d "$ups1DeviceName" --pd "$edgeDeviceName" -n $iotHub --force

    $upsDeviceExists=(az iot hub device-identity show --device-id $ups2DeviceName --hub-name $iotHub)
    if(!$upsDeviceExists){
        az iot hub device-identity create -n $iotHub -d "$ups2DeviceName" --am x509_ca 
    }
    az iot hub device-identity parent set -d "$ups2DeviceName" --pd "$edgeDeviceName" -n $iotHub --force

    $upsDeviceExists=(az iot hub device-identity show --device-id $ups3DeviceName --hub-name $iotHub)
    if(!$upsDeviceExists){
        az iot hub device-identity create -n $iotHub -d "$ups3DeviceName" --am x509_ca 
    }
    az iot hub device-identity parent set -d "$ups3DeviceName" --pd "$edgeDeviceName" -n $iotHub --force

    $upsDeviceExists=(az iot hub device-identity show --device-id $ups4DeviceName --hub-name $iotHub)
    if(!$upsDeviceExists){
        az iot hub device-identity create -n $iotHub -d "$ups4DeviceName" --am x509_ca 
    }
    az iot hub device-identity parent set -d "$ups4DeviceName" --pd "$edgeDeviceName" -n $iotHub --force
}

dotnet build .\simulated-x509-device\simulated-x509-device.csproj -r linux-x64 -p:PublishSingleFile=true
dotnet publish .\simulated-x509-device\simulated-x509-device.csproj -r linux-x64 -p:PublishSingleFile=true --self-contained true -o ..\upstreamDevice\

scp -i $HOME/.ssh/iotedge-vm-iot-playground -r ".\upstreamDevice" "$adminUserName@iot-playground-$edgeDeviceName.westeurope.cloudapp.azure.com:~/"
scp -i $HOME/.ssh/iotedge-vm-iot-playground -r ".\certificates\edgeVms\$edgeDeviceName\upstreamCerts" "$adminUserName@iot-playground-$edgeDeviceName.westeurope.cloudapp.azure.com:~/upstreamDevice"

Write-Host ""
Write-Host "Now log into the edge VM: ssh -i $HOME/.ssh/iotedge-vm-iot-playground $adminUserName@iot-playground-$edgeDeviceName.westeurope.cloudapp.azure.com"
Write-Host "Run the following commands: "
Write-Host "    $ cd upstreamDevice"
Write-Host "    $ chmod +x setup.upstreamDevices.sh"
Write-Host "    $ ./setup.upstreamDevices.sh $edgeDeviceName"
Write-Host ""
Write-Host "The ouptut should be like:"
Write-Host "● upstreamDevices.service - Launch upstream devices"
Write-Host "   Loaded: loaded (/etc/systemd/system/upstreamDevices.service; enabled; vendor preset: enabled)"
Write-Host "   Active: active (exited) since Tue 2021-01-26 14:03:04 UTC; 1h 26min ago"
Write-Host " Main PID: 1781 (code=exited, status=0/SUCCESS)"
Write-Host "    Tasks: 35 (limit: 4075)"
Write-Host "   CGroup: /system.slice/upstreamDevices.service"
Write-Host "           ├─1840 /home/azureiotadmin/upstreamDevice/simulated-x509-device edge1-ups1 iot-playground-devices-hub.azure-devices.net iot-playground-edge1-vm..."
Write-Host "           ├─1860 /home/azureiotadmin/upstreamDevice/simulated-x509-device edge1-ups2 iot-playground-devices-hub.azure-devices.net iot-playground-edge1-vm..."
Write-Host "           ├─1893 /home/azureiotadmin/upstreamDevice/simulated-x509-device edge1-ups3 iot-playground-devices-hub.azure-devices.net iot-playground-edge1-vm..."
Write-Host "           └─1928 /home/azureiotadmin/upstreamDevice/simulated-x509-device edge1-ups4 iot-playground-devices-hub.azure-devices.net iot-playground-edge1-vm..."
Write-Host "Ensure the processes are up&running (ps aux) if not, try to launch the setup script again."
