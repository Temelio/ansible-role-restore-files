#!/usr/bin/env bash

# Exit on the first error
set -e

# Manage logging
readonly SCRIPT_NAME=$(basename $0)
MAIN_LOG_FILE="{{ restore_files_main_log_file }}"
ERROR_LOG_FILE="{{ restore_files_error_log_file }}"

{% raw %}
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 3>&1 4>&2
exec > >(tee -ia "${MAIN_LOG_FILE}")
exec 2> >(tee -ia "${ERROR_LOG_FILE}")

# Create temporary directory
RESTORE_TMP_DIR="$(mktemp -d)"

# Always delete tmp dir
trap 'rm -rf "${RESTORE_TMP_DIR}"' EXIT


#================================ Define variables =============================

# Path variables
BACKUP_STORAGE=""

# Restore options
DO_RESTORE_FILES=0
DO_RESTORE_MYSQL=0
DELETE_FILE_BEFORE_RESTORE=0
FILE_GROUP=""
FILE_USERNAME=""

# Mysql variables
MYSQL="$(which mysql)"
MYSQL_CNF_FILE=""

# Create date variable
NOW="$(date +%Y-%m-%d__%H-%M-%S)"


#================================ Define functions =============================

# Commands used to log
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $*"
    logger -p user.notice -t $SCRIPT_NAME "$*"
}

err() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') => $*" >&2
    logger -p user.error -t $SCRIPT_NAME "$*"
}

console() {
    echo "$*"
}

# The command line help
display_help() {
    console " "
    console "Usage : $0 [option...] [-f my_path:my_dest] [-d my_database]"
    console " "
    console "  General options :"
    console "    -h        Display this help message and exit"
    console "    -p        Directory where backup files are"
    console " "
    console "  Database restore :"
    console "    -c        Mysql credential file"
    console "    -d        Do database restore, can be set multiple times"
    console "    -m        Do a mysql restore task, need at least one database"
    console " "
    console "  File restore :"
    console "    -D        Delete old files before restore files"
    console "    -f        Do file restore, can be set multiple times"
    console "    -g        Group of restored files"
    console "    -u        Owner of restored files"
    exit 1
}

# The mysql restore command
restore_mysql_databases() {

    log "Start Mysql restore ..."

    # A mysql restore nead at least one database to restore
    if [[ ${#databases[@]} -le 0 ]]; then
        err "Error : Mysql restore need at leat one database"
        display_help
    fi

    # A mysql restore nead one credentials file
    if [[ -z "${MYSQL_CNF_FILE}" || ! -f "${MYSQL_CNF_FILE}" ]]; then
        err "Error : Mysql restore need one credentials file"
        display_help
    fi

    for database in "${databases[@]}"; do
        ${MYSQL} --defaults-extra-file="${MYSQL_CNF_FILE}" \
            "${database}" < "${RESTORE_TMP_DIR}/${database}.sql"
    done

    log "Mysql restore finished"
}

# The files restore command
restore_files() {

    log "Start restore files task ..."

    # Copy files
    for file in "${files[@]}"; do

        # Get origin path part
        origin="${file%:*}"

        # Get dest path part and create the path
        dest="${file##*:}"
        mkdir -p "${RESTORE_TMP_DIR}/${dest}"

        # Check if file restore should delete old files
        if [[ ${DELETE_FILE_BEFORE_RESTORE} -eq 1 ]]; then
            log "Delete files into ${dest}/${origin}"
            rm -rf "${dest}/${origin}"
        fi

        # Copy files
        cp -af "${RESTORE_TMP_DIR}/${origin}/." "${dest}/"

        # Change owner if param is set
        if [[ -n "${FILE_USERNAME}" ]]; then
            chown -R "${FILE_USERNAME}" "${dest}/${origin}"
        fi

        # Change group if param is set
        if [[ -n "${FILE_GROUP}" ]]; then
            chgrp -R "${FILE_GROUP}" "${dest}/${origin}"
        fi
    done

    log "Restore files finished"
}

# Argument parse
parse_arguments() {

    local hasActions=0

    while getopts "c:d:g:Dhmf:p:u:" opt; do
        case $opt in
            c)
                MYSQL_CNF_FILE="${OPTARG}"
                ;;
            d)
                databases+=("${OPTARG}")
                ;;
            D)
                DELETE_FILE_BEFORE_RESTORE=1
                ;;
            g)
                FILE_GROUP="${OPTARG}"
                ;;
            h)
                display_help
                ;;
            m)
                DO_RESTORE_MYSQL=1
                hasActions=1
                ;;
            f)
                files+=("${OPTARG}")
                DO_RESTORE_FILES=1
                hasActions=1
                ;;
            p)
                BACKUP_STORAGE="${OPTARG}"
                ;;
            u)
                FILE_USERNAME="${OPTARG}"
                ;;
            :)
                err "Missing argument for -${OPTARG}"
                display_help
                ;;
            \?)
                err "Illegal option: -${OPTARG}"
                display_help
                ;;
        esac
    done
    shift $((OPTIND -1))

    if [[ ${hasActions} -eq 0 ]]; then
        err "Error : No restore defined"
        display_help
    elif [[ -z "${BACKUP_STORAGE}" || ! -d "${BACKUP_STORAGE}" ]]; then
        err "Error : Storage path is mandatory and should exist"
        display_help
    else
        log "Valid params received"
    fi
}


#================================ Create restore ===============================

# Begin log
log '#------------------------------'
log "Starting script ${SCRIPT_NAME}"
log '#------------------------------'

# Parse arguments
parse_arguments "$@"

# Extract last backup
last_backup="$(ls -AtR ${BACKUP_STORAGE}/*.tgz | head -1)"
log "Last backup file : '${last_backup}', process it"
tar -C "${RESTORE_TMP_DIR}" -xzf "${last_backup}"

# Do mysql restore if needed
if [[ ${DO_RESTORE_MYSQL} -gt 0 ]]; then
    restore_mysql_databases
fi

# Do file restore if needed
if [[ ${DO_RESTORE_FILES} -gt 0 ]]; then
    restore_files
fi

# End log
log '#-------------------------'
log "Script ended successfully"
log '#-------------------------'
{% endraw %}
