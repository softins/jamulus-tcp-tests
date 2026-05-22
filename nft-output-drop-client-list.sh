#!/bin/sh

case $# in
    0) echo "Need port number" ; exit 1 ;;
    1) port=$1 ;;
    *) echo "Too many arguments" ; exit 1 ;;
esac

# client list = 1013 = 0x03f5 => 0xf503 (LE byte order)
sudo nft add rule inet filter output udp sport $port @ih,16,16 0xf503 log
sudo nft add rule inet filter output udp sport $port @ih,16,16 0xf503 drop
sudo nft -a list ruleset


# CLM_SERVER_LIST = 1006 = 0x03ee => 0xee03 (LE byte order)
# CLM_RED_SERVER_LIST = 1018 = 0x03fa => 0xfa03 (LE byte order)
# CLM_CONN_CLIENTS_LIST = 1013 = 0x03f5 => 0xf503 (LE byte order)
# CLM_TCP_SUPPORTED = 1019 = 0x03fb => 0xfb03 (LE byte order)

# CONN_CLIENTS_LIST = 24 = 0x0018 => 0x1800 (LE byte order)
