#!/bin/bash

git pull
git submodule sync
git submodule update --recursive --init
