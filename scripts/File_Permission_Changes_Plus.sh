#!/usr/bin/env bash

. /etc/nastools_all_in_one/settings.sh
. ${config_dir}/nastools_all_in_one/basic_settings.sh
Media_DIR=${media_dir}

Green="\033[32m"
Red="\033[31m" 
Blue="\033[34m"
Font="\033[0m"

check_dir(){
# chown dir
find ${Media_DIR} \
    -type d \
    ! -group ${PGID} \
    -or \
    ! -user ${PUID}
find ${Media_DIR} \
    -type d \
    ! -group ${PGID} \
    -or \
    ! -user ${PUID} \
    -exec chown ${PUID}:${PGID} {} \;

# chmod dir
find ${Media_DIR} \
    -type d \
    ! -perm ${CFVR}
find ${Media_DIR} \
    -type d \
    ! -perm ${CFVR} \
    -exec chmod ${CFVR} {} \;
}

check_file(){
# chown file
find ${Media_DIR} \
    -type f \
    ! -group ${PGID} \
    -or \
    ! -user ${PUID}
find ${Media_DIR} \
    -type f \
    ! -group ${PGID} \
    -or \
    ! -user ${PUID} \
    -exec chown ${PUID}:${PGID} {} \;

# chmod file
find ${Media_DIR} \
    -type f \
    ! -perm ${CFVR}
find ${Media_DIR} \
    -type f \
    ! -perm ${CFVR} \
    -exec chmod ${CFVR} {} \;
}

check_change(){
check_dir
check_file
}

check_change