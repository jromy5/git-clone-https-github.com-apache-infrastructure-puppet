#!/bin/bash

git pull /etc/puppet
git submodule sync /etc/puppet
git submodule update --recursive --init /etc/puppet
