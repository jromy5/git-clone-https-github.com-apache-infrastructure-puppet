#!/bin/bash

_format() {
  echo "From: $MAIL_FROM"
  echo "To: $MAIL_TO"
  echo "Subject: Bug report for $PRODUCT [`date +%Y/%m/%d`]"
  echo ""
  BUG_COUNT=$1
  echo "+---------------------------------------------------------------------------+"
  echo "| Bugzilla Bug ID                                                           |"
  echo "|     +---------------------------------------------------------------------+"
  echo "|     | Status: UNC=Unconfirmed NEW=New         ASS=Assigned                |"
  echo "|     |         OPN=Reopened    VER=Verified    (Skipped Closed/Resolved)   |"
  echo "|     |   +-----------------------------------------------------------------+"
  echo "|     |   | Severity: BLK=Blocker CRI=Critical  REG=Regression  MAJ=Major   |"
  echo "|     |   |           MIN=Minor   NOR=Normal    ENH=Enhancement TRV=Trivial |"
  echo "|     |   |   +-------------------------------------------------------------+"
  echo "|     |   |   | Date Posted                                                 |"
  echo "|     |   |   |          +--------------------------------------------------+"
  echo "|     |   |   |          | Description                                      |"
  echo "|     |   |   |          |                                                  |"
  while true; do
    read LINE
    if [ -z "$LINE" ] ; then
      break
    fi
    BUG_ID=`echo "$LINE" | cut -f1`
    BUG_STATUS=`echo "$LINE" | cut -f2`
    case "$BUG_STATUS" in
      "UNCONFIRMED") BUG_STATUS="Unc" ;;
      "NEW")         BUG_STATUS="New" ;;
      "ASSIGNED")    BUG_STATUS="Ass" ;;
      "REOPENED")    BUG_STATUS="Opn" ;;
      "NEEDINFO")    BUG_STATUS="Inf" ;;
      "VERIFIED")    BUG_STATUS="Ver" ;;
      *)             BUG_STATUS="   " ;;
    esac
    BUG_SEVERITY=`echo "$LINE" | cut -f3`
    case "$BUG_SEVERITY" in
      "blocker")     BUG_SEVERITY="Blk" ;;
      "critical")    BUG_SEVERITY="Cri" ;;
      "regression")  BUG_SEVERITY="Reg" ;;
      "major")       BUG_SEVERITY="Maj" ;;
      "normal")      BUG_SEVERITY="Nor" ;;
      "minor")       BUG_SEVERITY="Min" ;;
      "enhancement") BUG_SEVERITY="Enh" ;;
      "trivial")     BUG_SEVERITY="Trv" ;;
      *)             BUG_SEVERITY="   " ;;
    esac
    BUG_DATE=`echo "$LINE" | cut -f4`
    BUG_DESC=`echo "$LINE" | cut -f5-`
    printf "|%5d|%-3.3s|%-3.3s|%-10.10s|%-50.50s|\n" \
      "$BUG_ID" \
      "$BUG_STATUS" \
      "$BUG_SEVERITY" \
      "$BUG_DATE" \
      "$BUG_DESC"
  done
  echo "+-----+---+---+----------+--------------------------------------------------+"
  printf "| Total %4d bugs %-57.57s |\n" "$BUG_COUNT" " "
  echo "+---------------------------------------------------------------------------+"
  printf "%5d bugs for %-20.20s\n" "$BUG_COUNT" "$PRODUCT" >&2
}

if [ -z "$1" ] ; then
  echo "Usage: $0 [from-addr] [to-addr] [product]"
  exit 1
fi

if [ -z "$2" ] ; then
  echo "Usage: $0 [from-addr] [to-addr] [product]"
  exit 1
fi

if [ -z "$3" ] ; then
  echo "Usage: $0 [from-addr] [to-addr] [product]"
  exit 1
fi

MAIL_FROM="$1"
MAIL_TO="$2"
PRODUCT="$3"
FILE="/tmp/buglog.$$"
# Username and password from /root/.my.cnf
cat << EOF | mysql bugs > $FILE
SELECT bugs.bug_id,bugs.bug_status,bugs.bug_severity,bugs.creation_ts,bugs.short_desc
  FROM bugs, products
  WHERE bugs.product_id=products.id and products.name='$PRODUCT'
    AND bugs.bug_status!='CLOSED'
    AND bugs.bug_status!='RESOLVED'
  ORDER BY bugs.bug_id;
EOF

# Use tail to strip the first (header) line off the file
LINES=`tail --lines=+2 $FILE | wc -l`
if [ "$LINES" -gt "0" ] ; then
  tail --lines=+2 $FILE | _format $LINES | /usr/sbin/sendmail -f "$MAIL_FROM" "$MAIL_TO"
fi
rm -f $FILE
