#!/bin/bash
EDGE_DEVICE_NAME=$1
if [[ -n "$EDGE_DEVICE_NAME" ]]; then
	echo "Launching upstream devices for $EDGE_DEVICE_NAME"
else
	echo "Must specify the edge device name i.e. launch-allDevices.sh edge1"
	exit -1
fi

UPSTREAM_DEVICE=$EDGE_DEVICE_NAME-ups1
/home/azureiotadmin/upstreamDevice/kill-upstreamDevice.sh $UPSTREAM_DEVICE
/home/azureiotadmin/upstreamDevice/launch-upstreamDevice.sh $UPSTREAM_DEVICE

UPSTREAM_DEVICE=$EDGE_DEVICE_NAME-ups2
/home/azureiotadmin/upstreamDevice/kill-upstreamDevice.sh $UPSTREAM_DEVICE
/home/azureiotadmin/upstreamDevice/launch-upstreamDevice.sh $UPSTREAM_DEVICE

UPSTREAM_DEVICE=$EDGE_DEVICE_NAME-ups3
/home/azureiotadmin/upstreamDevice/kill-upstreamDevice.sh $UPSTREAM_DEVICE
/home/azureiotadmin/upstreamDevice/launch-upstreamDevice.sh $UPSTREAM_DEVICE

UPSTREAM_DEVICE=$EDGE_DEVICE_NAME-ups4
/home/azureiotadmin/upstreamDevice/kill-upstreamDevice.sh $UPSTREAM_DEVICE
/home/azureiotadmin/upstreamDevice/launch-upstreamDevice.sh $UPSTREAM_DEVICE

