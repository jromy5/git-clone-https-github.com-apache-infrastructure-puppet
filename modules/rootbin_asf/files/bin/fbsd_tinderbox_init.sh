#!/bin/sh

tc='/space/scripts/tc'

sql1="truncate table jails; truncate table builds; truncate table ports_trees"
sql2="truncate table build_ports; truncate table ports; truncate table port_dependencies"

mysql -u root -D tinderbox -e "$sql1";
mysql -u root -D tinderbox -e "$sql2";

# Jails
tag=RELENG_9_0
osver=9.0-RELENG

${tc} createJail -j $osver-amd64 -d "FreeBSD $osver (amd64)" -u NONE -a amd64 -t $tag -I -m /usr/src
${tc} createJail -j $osver-i386  -d "FreeBSD $osver (i386)"  -u NONE -a i386  -t $tag -I -m /usr/src

# Ports Trees
${tc} createPortsTree -p FreeBSD -d "FreeBSD ports" -w http://www.freebsd.org/cgi/cvsweb.cgi/ports/ -u NONE -m /usr/ports

## Builds
builds=$(cd /space/scripts/etc/env/ ; /bin/ls -1 build*)

# amd64
for build in $builds; do
    build=$(echo $build |sed -e 's,build.,,')
    _osver=$(echo $build |cut -d- -f 1,2)

    arch=amd64
    _rc=$(echo $build |grep -c i386)
    if [ $_rc -eq 1 ]; then
      arch=i386
    fi
    jail="$_osver-$arch"

    ${tc} createBuild -b $build -j $jail -p FreeBSD -d "$build"
    p=/usr/home/ftp/pub/FreeBSD/ports/packages/$build
    if [ ! -d $p ]; then
      zfs create zroot$p
    fi
done

${tc} addUser -u pgollucci -e pgollucci@apache.org -p "$(cat /root/.pwtb)" -w
${tc} setWwwAdmin -u pgollucci

${tc} configDistfile -c /home/ftp/pub/FreeBSD/ports/distfiles
${tc} configCcache -e -c /ccache -s 12G
