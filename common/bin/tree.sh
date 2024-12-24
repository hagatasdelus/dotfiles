#!/bin/bash -xe

if [ $# -lt 1 ]
then
	TARGET_DIRECTORY="."
else
	TARGET_DIRECTORY=$1
fi

cd $TARGET_DIRECTORY ; 
echo ./ \(`pwd`/\) ; 
find . -type d -name '.svn' -prune -or -type d -exec echo {}\.\~ \; -or -type f -print | 
sort | 
sed '1d;s/^\.//;s/\/\([^/]*\)$/|-- \1/;s/\/[^/|]*/|-- /g' | 
sed 's/\.\~$/\//'

exit 0
