#!/bin/sh

ISO=FreeBSD-13.0-RELEASE-amd64-bootonly.iso
ISO_OUT=www/freebsd13.0-custom.iso

cd `dirname $0`

cp installerconfig img/etc

mkdir -p `dirname $ISO_OUT`
mkisofs -J -R -no-emul-boot \
  -V `isoinfo -d -i $ISO | awk '/Volume id/{print $3}'` \
  -b boot/cdboot \
  -o $ISO_OUT img
