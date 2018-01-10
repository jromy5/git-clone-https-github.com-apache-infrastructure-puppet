#!/bin/sh
# this file is managed in puppet - See: modules/mail_archives/files/scripts/mbox-raw-rsync.sh

/usr/bin/rsync \
  -rltvz --delete minotaur.apache.org::public-arch /x1/mail-archives/raw/

