#!/bin/sh

cd `dirname $0`

MIRROR=https://ftp.freebsd.org/pub/FreeBSD/releases

IMG=$MIRROR/ISO-IMAGES/13.1/FreeBSD-13.1-RELEASE-amd64-bootonly.iso
BASE=$MIRROR/amd64/13.1-RELEASE/base.txz
KERNEL=$MIRROR/amd64/13.1-RELEASE/kernel.txz

ensure_downloaded() {
  test -f `basename $1` || fetch $1
}

ensure_downloaded $IMG
ensure_downloaded $BASE
ensure_downloaded $KERNEL

mkdir -p img
tar -xf `basename $IMG` -C img
cp base.txz kernel.txz img/usr/freebsd-dist/
cp loader.conf.local img/boot/

