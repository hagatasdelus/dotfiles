#!/bin/bash

if [ $# -lt 1 ]; then
    TARGET_DIRECTORY="."
else
    TARGET_DIRECTORY=$1
fi

cd $TARGET_DIRECTORY
echo ./ \($(pwd)/\)

find . -type d -name '.svn' -prune -o \
    \( -type d -o -type f -o -type l \) -print |
    sort |
    sed '1d;s/^\.//;s/\/\([^/]*\)$/|-- \1/;s/\/[^/|]*/|-- /g' |
    while read line; do
        if [[ -L ".${line##*-- }" ]]; then
            # For symbolic links, display link destination
            target=$(readlink ".${line##*-- }")
            echo "$line -> $target"
        else
            # For normal files and directories
            if [[ $line =~ .*\.\~$ ]]; then
                echo "${line%\.\~}/"
            else
                echo "$line"
            fi
        fi
    done
