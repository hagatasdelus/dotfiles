#/bin/bash -xe
# -*- coding: utf-8 -*-

COMMAND_LINE="$@"
NUMBER_OF_ARGUMENTS=$#

if [ ${NUMBER_OF_ARGUMENTS} -lt 1 ]; then
    echo "Error: Specify one or more course names" >&2
    exit 1
fi

for COURSE in ${COMMAND_LINE}
do
    mkdir -p "${COURSE}/授業資料" "${COURSE}/レポート" "${COURSE}/テスト" "${COURSE}/過去問"

    for i in $(seq -f '%02g' 1 15)
    do
        mkdir -p "${COURSE}/授業資料/${i}"
    done
done

exit 0
