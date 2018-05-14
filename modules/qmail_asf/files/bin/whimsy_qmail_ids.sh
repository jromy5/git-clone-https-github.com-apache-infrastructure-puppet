#!/bin/bash

# Extract (most) qmail ids that have been used for user logins
#
# See
# https://issues.apache.org/jira/browse/INFRA-14566
# https://issues.apache.org/jira/browse/WHIMSY-113

cd ~apmail

# N.B. The regex does not match ids with fewer than 3 chars, nor does it match
# ids which contain special characters such as '-' or '_'
# These must be disallowed separately, see:
# https://issues.apache.org/jira/browse/WHIMSY-114

ls -a1 | sed -n '/^\.qmail-[a-z][a-z0-9][a-z0-9][a-z0-9]*$/ s/\.qmail-//p' | \
  ssh whimsy-vm4.apache.org 'cat > /srv/subscriptions/qmail.ids'
