#!/bin/bash
DEVICE_NAME=$1
if [[ -n "$DEVICE_NAME" ]]; then
	echo "Executing Device $DEVICE_NAME and writing log to $DEVICE_NAME.log"
    else
	echo "Must specify the device i.e. launch-upstreamDevice.sh edge1-ups1"
	exit -1
fi
/home/azureiotadmin/upstreamDevice/simulated-x509-device $DEVICE_NAME iot-playground-devices-hub.azure-devices.net $HOSTNAME \
	/home/azureiotadmin/upstreamDevice/upstreamCerts/iot-device-$DEVICE_NAME.cert.pfx \
	/home/azureiotadmin/upstreamDevice/upstreamCerts/azure-iot-test-only.root.ca.cert.pem >> /home/azureiotadmin/upstreamDevice/upstreamDevices.log &
