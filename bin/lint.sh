#!/bin/bash
# find newest commit
export commit=$(git rev-parse HEAD)
# make a list of files from the newest commit; grep is a hack to only lint pp files
export files=$(git --no-pager show --pretty="" --name-only -r $commit | grep pp|tr '\r\n' ' ')
# init.pp is there to make sure there is always a file to lint
bundle exec puppet-lint --no-nested_classes_or_defines-check --no-autoloader_layout-check modules/base/manifests/init.pp $files
