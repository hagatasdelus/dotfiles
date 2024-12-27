#/bin/bash -xe

if [ $# -lt 1 ]; then
    echo "Error: Specify one or more course names" >&2
    exit 1
fi

for COURSE in "$@"
do
    mkdir -p "${COURSE}/授業資料" "${COURSE}/レポート" "${COURSE}/テスト" "${COURSE}/過去問"

    for i in $(seq -f '%02g' 1 15)
    do
        mkdir -p "${COURSE}/授業資料/${i}"
    done
done


exit 0
