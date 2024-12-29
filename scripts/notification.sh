#!/bin/bash
# -*- coding: utf-8 -*-

set -o pipefail

FAILED_TITLE='Failed'
SUCCESS_TITLE='Success'

if [ $# -eq 0 ]; then
    osascript -e "display notification \"Please specify the command\" with title \"${FAILED_TITLE}\" sound name \"Sosumi\""
    exit 1
fi

OLD_COMMAND_LINE="$@"
NEW_COMMAND_LINE=''
NUMBER_OF_ARGUMENTS=$#
ARGUMENT_COUNTER=1

for EACH_ARGUMENT in ${OLD_COMMAND_LINE}
do
    if [[ "${EACH_ARGUMENT}" =~ [[:space:]\'\"] ]]; then
        NEW_COMMAND_LINE+="'${EACH_ARGUMENT//\'/\'\"\'\"\'}'"
    else
        NEW_COMMAND_LINE+="${EACH_ARGUMENT}"
    fi
    
    if [ ${ARGUMENT_COUNTER} -lt ${NUMBER_OF_ARGUMENTS} ]; then
        NEW_COMMAND_LINE+=" "
    fi
    ARGUMENT_COUNTER=$((ARGUMENT_COUNTER + 1))
done

echo "+ ${NEW_COMMAND_LINE}"

eval "${NEW_COMMAND_LINE}"
RESULT=$?

if [ ${RESULT} -eq 0 ]; then
    osascript -e "display notification \"Command completed successfully\" with title \"${SUCCESS_TITLE}\" sound name \"Hero\""
else
    osascript -e "display notification \"Command failed with exit code ${RESULT}\" with title \"${FAILED_TITLE}\" sound name \"Sosumi\""
fi

exit ${RESULT}
