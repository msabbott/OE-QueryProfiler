#!/bin/sh

# Run the grep into a temp file
grep -E " [0-9]* (SEARCH|ACCESS)" $1 > $1.tmp

mpro -pf connection.pf -p profile.p -param $1.tmp
