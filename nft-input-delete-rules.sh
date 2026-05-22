#!/bin/sh

case $# in
    0) echo "Need handle number(s)" ; exit 1 ;;
    *) ;;
esac

for h
do
    sudo nft delete rule inet filter input handle $h
done
sudo nft -a list ruleset
