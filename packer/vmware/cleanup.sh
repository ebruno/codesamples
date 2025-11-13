#!/usr/bin/env bash

rm -r -f output-artifacts;
find . -name "*~" -exec rm -f {} \;
find . -name "#*#" -exec rm -f {} \;
rm -f sha*sums.txt;
rm -r -f assets;
rm -f archlinux.pkrvars.hcl;
