#!/bin/bash -e
# -*- coding: utf-8 -*-

COMMAND_LINE="$@"
NUMBER_OF_ARGUMENTS=$#

if [ ${NUMBER_OF_ARGUMENTS} -lt 1 ]; then
    echo "Command Failed: Specify one or more course names." >&2
    exit 1
fi

for COURSE in ${COMMAND_LINE}; do
    mkdir -p "${COURSE}/lectures" "${COURSE}/reports" "${COURSE}/tests" "${COURSE}/pastexams"

    for i in $(seq -f '%02g' 1 15); do
        mkdir -p "${COURSE}/lectures/${i}"
    done
    echo "Course Setup Done >> ${COURSE}"
done

exit 0
