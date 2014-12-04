#!/bin/sh

die() {
  echo "$@" >&2
  exit 1
}

ip="$1"
if [ -z "$ip" ]; then
    die "Usage: $0 ip"
fi

if [ x"`uname -s`" != x"FreeBSD" ]; then
    die "Not FreeBSD; bailing"
fi

if ! /sbin/pfctl -t fail2ban -T show >/dev/null; then
    die "fail2ban doesn't seem to be working"
fi

set -x
/usr/local/bin/sudo /sbin/pfctl -t fail2ban -T add "$ip"
/usr/sbin/tcpdrop -al | ip=ip perl -ane 'print if $F[3] eq $ENV{ip}' | /usr/bin/xargs -n5 /usr/local/bin/sudo
