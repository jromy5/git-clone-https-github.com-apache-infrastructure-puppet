#!/bin/sh
# usage: add <path to list>
# To add all CVS committers to the allow list for a mailing
# list. This avoids having to moderate the first cvs commit
# msg on a new list. Which generally means you avoid having
# to moderate through a large number of them. As the initial
# batch tends to be large. dirkx@webweaving.org
#
for i in `grep apcvs /etc/group | sed -e 's/,/ /g' | sed -e 's/.*://'`
do
	ezmlm-sub $1/allow $i@apache.org
done

