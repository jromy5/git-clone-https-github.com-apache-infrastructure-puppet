#!/bin/bash

EYAML=$(find ./data -iname "*.eyaml")

for i in $EYAML
do
  echo "Recrypting $i"
  eyaml recrypt -n gpg $i --gpg-always-trust --gpg-recipients-file data/hiera-eyaml-gpg.recipients
done  

