#!/bin/bash

echo -e "architecture: \c "
read arch
echo -e "SSID: \c "
read ssid
echo -e "password: \c "
read pass

echo Copy/paste the following:
echo export MIX_TARGET=$arch
echo export NERVES_NETWORK_SSID=$ssid
echo export NERVES_NETWORK_PSK=$pass
