#!/bin/sh

if [ $# -ne 4 ]; then
  echo "USAGE: $0 notifyee listname moderators private? < text-to-append" >&2
  exit 1
fi

notifyee="$1"
listname="$2"
moderators="$3"
private_p="$4"
appendix="`cat`"

/usr/sbin/sendmail -f private@infra.apache.org -t <<EOM
From: apmail@apache.org
To: $notifyee
Reply-To: private@infra.apache.org
Subject: [NOTICE] List created: $listname
Content-type: text/plain; charset=UTF-8

As requested by you, the following mailing list has been created:
	$listname
	Moderators: $moderators
	This list is `
if [ 0 = "$private_p" ]; then echo "public"; else echo "private"; fi`.

`if [ -n "$appendix" ]; then printf "[[[\n%s\n]]]" "$appendix"; fi`

---

The list will start accepting mail in 60 minutes from now.  If it's a public
list, it will appear on https://lists.apache.org/ within a few minutes of
the first post to it.

With any issues, please contact the Infrastructure team by replying.
EOM
