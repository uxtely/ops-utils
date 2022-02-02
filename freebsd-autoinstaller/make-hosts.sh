#!/bin/sh

MY_IP=`cat /root/hostip`

echo "::1 localhost localhost.my.domain"
echo "127.0.0.1 localhost localhost.my.domain"
echo "$MY_IP orch.example.com"
