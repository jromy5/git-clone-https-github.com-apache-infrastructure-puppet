#!/bin/bash

############################################################################
# Licensed to the Apache Software Foundation (ASF) under one or more       #
# contributor license agreements.  See the NOTICE file distributed with    #
# this work for additional information regarding copyright ownership.      #
# The ASF licenses this file to you under the Apache License, Version 2.0  #
# (the "License"); you may not use this file except in compliance with     #
# the License.  You may obtain a copy of the License at                    #
#                                                                          #
#     http://www.apache.org/licenses/LICENSE-2.0                           #
#                                                                          #
# Unless required by applicable law or agreed to in writing, software      #
# distributed under the License is distributed on an "AS IS" BASIS,        #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. #
# See the License for the specific language governing permissions and      #
# limitations under the License.                                           #
############################################################################

# Script useful for extracting gz files and symlinking .mbox

# Run this script from inside the directory where you
# want to extract gz files and symlink .mbox to the
# resultant extracted files.

# Tested on SunOS (sparc); FreeBsd, Linux (Ubuntu) and OSX Darwin (High Siera)

if [ ! -f *.gz ]; then
  echo "No .gz files present in this directory, exiting";
  exit 1
fi

echo -n "Do you wish to overwrite existing extracted files?"
read yesno
if echo "$yesno" | grep -i "^y" ;then
  overwrite="y";
else
  overwrite="n";
fi

platform="$(uname | tr '[:upper:]' '[:lower:]')"

if [ $platform = 'sunos' ] || [ $platform = 'darwin' ]; then
  declare -a name=`ls *.gz | cut -f1 -d'.'`;
  ZCAT=`which gzcat`;
elif [ $platform = 'linux' ] || [ $platform = 'freebsd' ]; then
  declare -a name=`basename -s .gz *.gz`;
  ZCAT=`which zcat`;
else
  echo "Your platform is unsupported/untested for this script";
  exit 1
fi

curdir=`pwd`;

for extract in $name; do
  size=`stat -c%s $extract.gz`
  if [ $overwrite == "y" ] || [ ! -f $extract ] && [ $size != 27 ]; then
    $ZCAT $extract.gz > $extract;
    echo "$extract has been extracted (and overwritten if already existed)";
  elif  [ -f $extract ] && [ $size != 27 ]; then
    echo "$extract exists and is not empty and so was skipped from extraction";
  elif [ $size == 27 ]; then
    echo "gz archive is empty so not extracting";
  fi
    if [ -L $extract.mbox ];then
      echo "Symlink exists, skipping ...";
    else
      echo "Creating symlink to $extract.mbox ...";
      ln -s $curdir/$extract $extract.mbox;
    fi
    echo "Size = $size";
done

echo "All Done: You might want to run the mod-mbox-util script now, then re-index.";

