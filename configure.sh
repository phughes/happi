#!/bin/bash

echo -e "architecture: \c "
read arch
echo -e "SSID: \c "
read ssid
echo -e "password: \c "
read pass

export MIX_TARGET="$arch"
export NERVES_NETWORK_SSID="$ssid"
export NERVES_NETWORK_PSK="$pass"
