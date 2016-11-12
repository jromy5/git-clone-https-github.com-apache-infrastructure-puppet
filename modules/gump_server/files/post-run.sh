#!/bin/sh

free
ps -C java -f -w -w | fgrep surefire
for i in `ps -C java -o pid,command -w -w | fgrep surefire | cut -c 1-5`; do
    echo "Killing $i"
    kill -9 $i
done
free
