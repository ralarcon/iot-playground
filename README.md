# iot-playground
Source and assets for setup and make PoCs for IoT

ProvisionEdgeVM.ps1 generate the certificates for a certain Edge device and provision a VM using those certificates. This automatically register the edge device using a pre-configured DPS. That DPS have two enrollment groups (one for edge devices based on the Root CA and other for upstream devices based on the Intermediate CA).

It will try to use DPS configured with CA and Intermediate CA certificates generated using.

The VMs are Ubuntu 18.04 with IoT Edge Installed (+ az cli & azcopy) and ready.

The VMs are provisioned using an ARM template with a Cloud Init script which provides the proper configuration to use the DPS service:
* Based on [Run Azure IoT Edge on Ubuntu Virtual Machines](https://docs.microsoft.com/en-us/azure/iot-edge/how-to-install-iot-edge-ubuntuvm?WT.mc_id=github-iotedgevmdeploy-pdecarlo) 
* Original repo: https://github.com/Azure/iotedge-vm-deploy

Certificate generation based on https://github.com/Azure/iotedge.git (modified to change the expiration default for PoC purspose). NEVER USE IN PRODUCTION.