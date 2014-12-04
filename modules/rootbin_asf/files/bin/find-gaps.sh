#!/bin/sh

# Cycle through the subversion revisions that have been generated since
# the last run of this script (rev= asf.next - 1) and ensure that, for
# each revision in the svn repository, we have an 'asf.xxx' file that is
# an incremental dump of that revision.  This is necessary because
# an svnadmin load (e.g., a cvs2svn conversion) does not trigger the
# post-commit hooks that generate hot-backup deltas.  Therefore,
# there are 'gaps' whenever a dump is loaded.  This script generates
# any missing deltas and moves the existing deltas into an organized
# directory structure with a max 1000 files per directory.
#
# Now, wouldn't it be nice if we had a corresponding restore script?

hotbackupdir=/x1/svn/hot-backups
nextdelta="$hotbackupdir/asf.next"
svn_repo=/x1/svn/asf

if [ -e $nextdelta ]; then
   i=`cat "$nextdelta"`
else
   i=250000
fi
list_max=`/usr/local/svn/bin/svnlook youngest $svn_repo`

while [ $i -le $list_max ]; do
  lonum=$(( $i % 1000 ))
  hinum=$(( $i / 1000 ))
  dirname=`printf "asf-%04d" $hinum`
  filname=`printf "%03d" $lonum`
  if [ ! -d "$hotbackupdir/$dirname" ]; then
    /bin/mkdir "$hotbackupdir/$dirname"
  fi
  if [ -e "$hotbackupdir/asf.$i.propchanged" ]; then
    /bin/mv "$hotbackupdir/asf.$i.propchanged" "$hotbackupdir/$dirname/$filname.propchanged"
  fi
  if [ ! -e "$hotbackupdir/$dirname/$filname" ]; then
    if [ -e "$hotbackupdir/asf.$i" ]; then
      /bin/mv "$hotbackupdir/asf.$i" "$hotbackupdir/$dirname/$filname"
    else
      /usr/local/svn/bin/svnadmin dump --deltas --incremental -q -r $i \
           $svn_repo > "$hotbackupdir/$dirname/$filname"
    fi
  fi
  i=$(( 1 + $i ))
done
echo $i > $nextdelta
