#!/bin/bash

# CONFIGURATION
DIR_SOURCE="./source"
DIR_DESTINATION="../delme_destination"
DIR_NAME_DESTINATION_IGNORE="ignore/real_ignore" # inside DIR_DESTINATION, this files should be saved
DIR_BACKUP="./storage/bkp" # subdir = current date

function preCopyActions {
    echo "preCopyActions"
}

function postCopyActions {
    echo "postCopyActions"
}
# END CONFIGURATION

DIR_IGNORE="$DIR_DESTINATION/$DIR_NAME_DESTINATION_IGNORE"

NOW="$(date +'%B %d, %Y %T')"
RED="\033[1;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
PURPLE="\033[1;35m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"
RESET="\033[0m"

function quit {
    echo -e "${YELLOW}Quit. Reason: ${WHITE}$1"
    # reset color
    echo -e "${RESET}"
    exit
}

# $1 type, $2 path
function stringIsEmptyTerminate {
    if stringIsEmpty $2; then
        echo -e "${RED}'$1' directory path is empty"
        quit "Required directory path: '${1}' is empty"
    fi
}

# $1 path
function stringIsEmpty {
    if [ -z "${1// }" ]; then
        true
    else
        false
    fi
}

# $1 type, $2 path, if non exists - terminate
function dirExistsTerminate {
    stringIsEmptyTerminate $1 $2
    if ! dirExists $1 $2; then
        quit "Required directory doesn't exits: ${2}"
    fi
}

# $1 type, $2 path, if non exists - terminate
function dirExists {
    if stringIsEmpty $2; then
        echo -e "${YELLOW}'$1' directory path is empty${RESET}"
        false
    else
        if [ -d $2 ]; then
            echo -e "${GREEN}'$1' directory '${2}' exists${RESET}"
            true
        else
            echo -e "${YELLOW}'$1' directory '${2}' doesn't exitsts${RESET}"
            false
        fi
    fi
}

# $1 type, $2 path
function dirIsEmptyTerminate {
    if ! dirIsEmpty $2; then
        echo -e "${GREEN}'$1' directory is not empty${RESET}"
        false
    else
        echo -e "${RED}'$1' directory is empty${RESET}"
        quit "Required directory: ${2}"
    fi
}

# $1 path
function dirIsEmpty {
    if [ "$(ls -A $1)" ]; then
        false
    else
        true
    fi
}

# No - default
OPTIONS_CONFIRM="No Yes"
function dialogConfirm {
    echo -e $1
    RESPONSE=false
    select opt in $OPTIONS_CONFIRM; do
        if [ "$opt" = "Yes" ]; then
            RESPONSE=true
            break
        else
            break
        fi
    done
    echo -e "Response: ${RESPONSE}${RESET}"
    $RESPONSE
}

# greetings
echo -e "${YELLOW}Hello, ${WHITE}man.${RESET}"
echo -e "We are going to make deploy"
# check directories exits end has content
echo -e "Check configs..."
dirExistsTerminate "Source" $DIR_SOURCE
dirIsEmptyTerminate "Source" $DIR_SOURCE
dirExistsTerminate "Destination" $DIR_DESTINATION
dirExistsTerminate "Backup" $DIR_BACKUP

DIR_IGNORE_EXISTS=false
if ! stringIsEmpty $DIR_NAME_DESTINATION_IGNORE; then
    if dirExists "Ignore" $DIR_IGNORE; then
        if ! dirIsEmpty $DIR_IGNORE; then
            DIR_IGNORE_EXISTS=true
        fi
    fi
fi

# apply pre copy actions from config
echo -e "Apply ${WHITE}pre copy${RESET} actions..."
preCopyActions
echo -e "Pre copy actions applied"
# clean previous backups with prompt
if dialogConfirm "${CYAN}Remove old archives?"; then
    \rm -rf $DIR_BACKUP
    mkdir $DIR_BACKUP
fi
# backup destination directory
echo -e "Backup to '${WHITE}${DIR_BACKUP}/${NOW}${RESET}'"
yes | cp -Rf $DIR_DESTINATION "$DIR_BACKUP/${NOW}"
# copy source to destination
echo -e "Copy source '${WHITE}${DIR_SOURCE}${RESET}' to destination '${WHITE}${DIR_DESTINATION}${RESET}'"
yes | cp -Rf "$DIR_SOURCE/." $DIR_DESTINATION
# restore ignore from backup
if $DIR_IGNORE_EXISTS; then
    echo -e "Restore ignore directory '${WHITE}${DIR_IGNORE}${RESET}'"
    # clean ignore directory
    \rm -rf $DIR_IGNORE
    mkdir $DIR_IGNORE
    # copy ignore from backup to destination
    yes | cp -Rf "$DIR_BACKUP/$NOW/$DIR_NAME_DESTINATION_IGNORE/." $DIR_IGNORE
fi

# apply post copy actions from config
echo -e "Apply ${WHITE}post copy${RESET} actions..."
postCopyActions
echo -e "Post copy actions applied"

# exit success
quit 666

# INFO: check param exists/nonexists
# if [ -z "$1" ]; then
#     echo usage: $0 directory
#     exit
# else
#     echo -e $0 directory
# fi
