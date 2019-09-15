#!/usr/bin/env bash

FILE=doge.p8

# Replace export path with current folder
BASE=$(basename $(pwd))
sed -i "1088c\ \ \ path = '$BASE'" $FILE

# Export for web
pico8 -x $FILE

# Move to dist folder
mkdir -p dist
mv index.js index.html dist
cp label.png dist/placeholder.png
cp favicon.png dist/.
