#!/bin/bash --login
DEVICE_NAME=$1
HUB=$2
EDGE_HOST=$3
if [[ -n "$DEVICE_NAME" ]]; then
	echo "Removing Device $DEVICE_NAME"
else
	echo "Must specify the device i.e. kill-upstreamDevice.sh edge1-ups1"
	exit -1
fi
/bin/ps axf | /bin/grep "simulated-x509-device $DEVICE_NAME" | /bin/grep -v grep
/bin/ps axf | /bin/grep "simulated-x509-device $DEVICE_NAME" | /bin/grep -v grep | awk '{print "/bin/kill -9 " $1}' | /bin/sh
