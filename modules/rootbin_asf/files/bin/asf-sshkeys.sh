#!/bin/sh
# Workaround for SunOS
if [ -z "$ASF_SSHKEYS_SH_GUARD" ] && [ -x /usr/xpg4/bin/sh ]; then
  exec env ASF_SSHKEYS_SH_GUARD=y /usr/xpg4/bin/sh "$0" "$@"
fi


PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

# Script to manage the /etc/ssh/ssh_keys/**/*.pub hierarchy,
# include symlinks and dir/file permissions, on various platforms.

SED_BIN=`which sed`
KEYS_FOLDER="/etc/ssh/ssh_keys"
KEYS_REPO="https://svn.apache.org/repos/infra/infrastructure/trunk/ssh_keys"
KEYS_GROUP="sshusers"
KEYS_GID="2680"
SVN_BIN=`which svn`

OSNAME=`uname -s`
case "$OSNAME" in
  SunOS) SVN_BIN=/opt/subversion-current/bin/svn;;
  Darwin) 
    KEYS_FOLDER="/etc/ssh_keys" 
    AUTH_FILE="/private/etc/authorized_keys"
    ;;
esac

case "$OSNAME" in
  FreeBSD) group=wheel;;
  Linux)   group=admin;;
  *)       group=root;;
esac

usage() {

    echo >&2
    echo >&2 "Usage:"
    echo >&2 "$0 [-hipuv]"
    echo >&2 "    -h display this help message"
    echo >&2 "    -i initialize /etc/ssh/ssh_keys"
    echo >&2 "    -p set/verify perms on /etc/ssh/ssh_keys and *.pub"
    echo >&2 "    -u svn up /etc/ssh/ssh_keys"
    echo >&2 "    -v be verbose"
    echo >&2 "    if -p and -u, svn up will be run first"
    echo >&2 "    -u implies -p"

    exit 1
}

prepareDarwin() {

    if [ "x`uname -s`" = "xDarwin" ]; then
        rm -f $AUTH_FILE
        touch $AUTH_FILE
    fi 
}

init() {

    add_group
    folder
    update
    prepareDarwin
    keypermsusers
    keypermsservices
}

folder() {

    if [ ! -d ${KEYS_FOLDER} ]; then
        mkdir -p ${KEYS_FOLDER}
    fi

    chown root:${KEYS_GROUP} ${KEYS_FOLDER}
    chmod 750 ${KEYS_FOLDER}
}

update() {
    
    if [ -d ${KEYS_FOLDER}/.svn ]; then
        $SVN_BIN up ${KEYS_FOLDER}
    else
        $SVN_BIN co ${KEYS_REPO} ${KEYS_FOLDER}
    fi
}

listgroup() {
    local mygroup=$1
    local g

    case "$OSNAME" in
    Darwin)
        g=`/usr/bin/dscl . read /groups/$mygroup GroupMembership | sed -e 's/^GroupMembership: //'`
       ;;
    *)
        g=`grep $mygroup /etc/group | sed -e 's,.*:,,' |sed -e 's/,/ /g'`
        ;;
    esac
    
    echo $g
}

keys() {
    local dir=$1

    local u
    local k
    local l

    ## user in group
    for u in `listgroup ${KEYS_GROUP}` ; do
        if [ -f $dir/$u.pub ]; then
            if [ "x`uname -s`" = "xDarwin" ]; then
                cat $dir/$u.pub >> $AUTH_FILE
            else 
                l=${KEYS_FOLDER}/$u.pub
                if [ ! -L $l ]; then
                  echo "NEW ACCESS: $u"
                  ln -s $dir/$u.pub $l
                fi
            fi
        else
          if [ "$dir" = "${KEYS_FOLDER}/people" ]; then
            echo "$u is in sshusers but has no key in svn ($dir/$u.pub)"
          fi
        fi        
    done
    chown root:$KEYS_GROUP $dir
    chmod 0750 $dir
    chown root:$group $dir/*.pub
    chmod 0644 $dir/*.pub
}

keypermsusers() {

    keys ${KEYS_FOLDER}/people
}

keypermsservices() {

    keys ${KEYS_FOLDER}/services
}

add_group() {
  
    case "$OSNAME" in
        FreeBSD)
          if ! pw group show "${KEYS_GROUP}" >/dev/null 2>&1; then
            pw group add ${KEYS_GROUP} -g ${KEYS_GID}
          fi
          ;;
        *) 
          /usr/sbin/groupadd -g ${KEYS_GID} ${KEYS_GROUP} 2>/dev/null
        ;;
    esac
}

init=0
perms=0
update=0
verbose=0

while getopts hipuv o; do
    case "$o" in
        h) usage;;
        i) init=1;;
        p) perms=1;;
        u) 
            update=1
            perms=1
            ;;
        v) verbose=1;;
    esac
done

if [ $verbose -eq 1 ]; then
    set -x
fi

## gaurantee order of calls if passed multiple flags at once
if [ $init -eq 1 ]; then
    init
fi

if [ $update -eq 1 ]; then
    update
fi

if [ $perms -eq 1 -o $update -eq 1 ]; then
    folder
    prepareDarwin
    keypermsusers
    keypermsservices
fi

# OPIE does not exist for now on Mac OS X. sctemme 20100808.
if [ "x$OSNAME" != "xDarwin" ]; then
    /root/bin/opiecheck.sh
fi

exit 0
