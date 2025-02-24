#!/bin/bash -e
# -*- coding: utf-8 -*-

set -o pipefail

FAILED_TITLE='Failed'
SUCCESS_TITLE='Success'

NEW_COMMAND_LINE=''
NUMBER_OF_ARGUMENTS=$#
ARGUMENT_INDEX=1

if [ ${NUMBER_OF_ARGUMENTS} -eq 0 ]; then
    osascript -e 'display notification "Please specify the command" with title "${FAILED_TITLE}" sound name "Sosumi"'
    exit 1
fi

NEW_COMMAND_LINE=$(printf "%q " "$@")
echo "+ ${NEW_COMMAND_LINE}"

eval "${NEW_COMMAND_LINE}"
RESULT=$?

if [ ${RESULT} -eq 0 ]; then
    osascript -e "display notification \"Command completed successfully\" with title \"${SUCCESS_TITLE}\" sound name \"Hero\""
else
    osascript -e "display notification \"Command failed with exit code ${RESULT}\" with title \"${FAILED_TITLE}\" sound name \"Sosumi\""
fi

exit ${RESULT}
