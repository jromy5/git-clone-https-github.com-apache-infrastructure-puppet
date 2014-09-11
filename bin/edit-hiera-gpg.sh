#!/bin/bash

eyaml edit -n gpg ${1} --gpg-always-trust --gpg-recipients-file data/hiera-eyaml-gpg.recipients
