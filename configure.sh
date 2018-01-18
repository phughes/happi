#!/bin/bash

echo -e "architecture: \c "
read
export MIX_TARGET=$REPLY
echo -e "SSID: \c "
read
export NERVES_NETWORK_SSID=$REPLY
echo -e "password: \c "
read
export NERVES_NETWORK_PSK=$REPLY