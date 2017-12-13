#!/bin/bash
export commit=$(git rev-parse HEAD)
export files=$(git --no-pager show --pretty="" --name-only| tr '\r\n' ' ')
bundle exec puppet-lint --no-nested_classes_or_defines-check --no-autoloader_layout-check -r $commit $files
