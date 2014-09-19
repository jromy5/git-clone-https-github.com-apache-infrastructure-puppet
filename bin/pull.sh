#!/bin/bash

git pull

if [ ! -f "./Puppetfile" ] ; then 
  echo 'It looks like you are not running this script relative to the root of the repo. Until we make it more sensible you need too. Sorry.' 
  exit 1
fi

export PUPPETFILE_DIR="3rdparty-modules"
PUPPETFILE_DIR="3rdparty-modules" r10k puppetfile check --verbose --trace
PUPPETFILE_DIR="3rdparty-modules" r10k puppetfile install 
