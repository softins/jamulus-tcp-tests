#!/bin/sh

case $# in
    0) echo "Need port number" ; exit 1 ;;
    1) port=$1 ;;
    *) echo "Too many arguments" ; exit 1 ;;
esac

sudo nft add rule inet filter input tcp dport $port log
sudo nft add rule inet filter input tcp dport $port drop
sudo nft -a list ruleset
