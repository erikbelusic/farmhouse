#!/usr/bin/env bash

mkdir -p ~/.farmhouse

farmhouseRoot=~/.farmhouse

cp -i src/stubs/Farmhouse.yaml $farmhouseRoot/Farmhouse.yaml
cp -i src/stubs/after.sh $farmhouseRoot/after.sh
cp -i src/stubs/aliases $farmhouseRoot/aliases

echo "Farmhouse initialized!"
