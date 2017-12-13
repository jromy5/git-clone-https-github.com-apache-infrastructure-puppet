#!/bin/bash
export commit=$(git rev-parse HEAD)
export files=$(git --no-pager show --pretty="" --name-only -r $commit | grep -v .*sh|tr '\r\n' ' ')
bundle exec puppet-lint --no-nested_classes_or_defines-check --no-autoloader_layout-check modules/base/manifests/init.pp $files
