#!/bin/sh
set -eu
B=/bin/busybox
$B mkdir -p /mnt/test
$B mount -t ext4 /dev/vda /mnt/test
$B ip link set lo up
$B cat /sys/class/net/eth0/address
[ "$($B cat /sys/class/net/eth0/address)" = 52:54:00:12:34:56 ]
$B cat /sys/devices/system/cpu/online
$B head -n 3 /proc/meminfo
/mnt/test/os-probe /mnt/test
$B sha256sum -c /mnt/test/io.expected.sha256
$B sync
$B umount /mnt/test
$B mount -t ext4 -o ro /dev/vda /mnt/test
$B sha256sum -c /mnt/test/io.expected.sha256
$B umount /mnt/test
echo LINUX_OS_CHECK_PASS
