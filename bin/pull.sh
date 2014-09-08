#!/bin/bash

echo "This might be useful reading... http://joncairns.com/2011/10/how-to-use-git-submodules/"

git pull .
git submodule sync .
git submodule update --recursive --init .
