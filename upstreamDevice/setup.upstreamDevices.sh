#!/bin/bash
EDGE_DEVICE_NAME=$1
if [[ -n "$EDGE_DEVICE_NAME" ]]; then
	echo "Setting up upstream devices launch service for $EDGE_DEVICE_NAME"
else
	echo "Must specify the edge device name i.e. setup.upstreamDevices.sh edge1"
	exit -1
fi

# Prepare logrotate config for upstreamDevices.logs
cp /home/azureiotadmin/upstreamDevice/upstreamDevice.logrotate.conf /home/azureiotadmin/upstreamDevice/upstreamDevices
sudo chown root:root /home/azureiotadmin/upstreamDevice/upstreamDevices
sudo chmod 0644 /home/azureiotadmin/upstreamDevice/upstreamDevices
sudo mv -f /home/azureiotadmin/upstreamDevice/upstreamDevices /etc/logrotate.d/upstreamDevices

chmod +x /home/azureiotadmin/upstreamDevice/kill-upstreamDevice.sh
chmod +x /home/azureiotadmin/upstreamDevice/launch-allDevices.sh
chmod +x /home/azureiotadmin/upstreamDevice/launch-upstreamDevice.sh
chmod +x /home/azureiotadmin/upstreamDevice/simulated-x509-device

# Ensure no service exists
sudo systemctl stop upstreamDevices

sudo sed "s/##EDGE_DEVICE##/$EDGE_DEVICE_NAME/g" /home/azureiotadmin/upstreamDevice/upstreamDevices.service.conf > /home/azureiotadmin/upstreamDevice/upstreamDevices.service
sudo chown root:root /home/azureiotadmin/upstreamDevice/upstreamDevices.service
sudo mv /home/azureiotadmin/upstreamDevice/upstreamDevices.service /etc/systemd/system/upstreamDevices.service

sudo systemctl daemon-reload
sudo systemctl enable upstreamDevices
sudo systemctl start upstreamDevices
sudo systemctl status upstreamDevices