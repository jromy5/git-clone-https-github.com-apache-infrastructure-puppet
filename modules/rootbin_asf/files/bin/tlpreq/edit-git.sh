#!/bin/sh

set -e
set -x

GIT=/usr/bin/git
PODLING_DIR=$1 # location of incubating repo
NAME=$2 # name of TLP
TLP_REPO=$3 # name of specific TLP .git repo

if [ -n "$PODLING_DIR" ] && [ -n "$NAME" ] && [ -n "$TLP_REPO" ]; then
    if [ ! -d "$PODLING_DIR" ]; then
       echo "$PODLING_DIR does not exist, aborting."  >&2
       exit 1
    fi
    if ! /usr/bin/host "$NAME".apache.org. >/dev/null ; then
       echo "$NAME does not appear to be a TLP (no DNS)" >&2
       exit 1
    fi

    # From asfgit-admin NOTES on TLP move:
    # Change commit mailing list address in project.git/config
    COMMITS_EMAIL="commits@$NAME.apache.org"
    if ! /usr/local/bin/swaks -q RCPT -t "$COMMITS_EMAIL" -s mx1-lw-us.apache.org. >/dev/null; then
        echo "Runtime error: '$COMMITS_EMAIL' rejected by MX" >&2
        exit 2
    fi
    $GIT config -f "$PODLING_DIR/config" --replace-all hooks.asfgit.recips "$COMMITS_EMAIL"

    # change dir to git dir so we can run `git remote` properly
    cd "$PODLING_DIR"
    # Update the mirror destination name in project.git/config
    $GIT remote set-url asf-mirror "https://git-wip-us.apache.org/repos/asf/$TLP_REPO" 

    # If a github mirror exists, name change needs to be reflected there too (project.git/config)
    $GIT remote set-url github-mirror "https://github.com/apache/$TLP_REPO"
    exit 0
else
    echo "Usage: edit-git <git-repo> <project-name>"
    exit 1
fi
