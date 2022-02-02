#!/bin/sh

echo "Creating an ISO"
sh /root/extract-release-iso.sh
sh /root/make-hosts.sh $1 > /root/img/etc/hosts
sh /root/make-iso.sh

