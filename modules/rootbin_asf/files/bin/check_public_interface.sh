#!/bin/sh

PATH=/bin:/usr/bin:/sbin:/usr/sbin

# We are confirming that igb0 hasn't locked up.  Our own switch doesn't
# have an IP address in that vlan, so we ping something else (which is farther
# from us, network-wise).
switch=140.211.11.1
ping -t 1 -c 1 $switch > /dev/null && exit 0

echo mino cannot ping the switch at $switch - toggling igb0 interface
ifconfig igb0 down
sleep 5
ifconfig igb0 up

exit 0
