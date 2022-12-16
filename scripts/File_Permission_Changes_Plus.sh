#!/usr/bin/env bash

. /etc/nastools_all_in_one/settings.sh
. ${config_dir}/nastools_all_in_one/basic_settings.sh
Media_DIR=${media_dir}

Green="\033[32m"
Red="\033[31m" 
Blue="\033[34m"
Font="\033[0m"
INFO="[${Green}INFO${Font}]"
ERROR="[${Red}ERROR${Font}]"
Time=$(date +"%Y-%m-%d %T")

INFO(){
echo -e "${Time} ${INFO} ${TEXT}"
echo -e "${Time} INFO  ${TEXT}" >> ${config_dir}/scripts/File_Permission_Changes_Plus/logs/main.log
}
ERROR(){
echo -e "${Time} ${ERROR} ${TEXT}"
echo -e "${Time} ERROR  ${TEXT}" >> ${config_dir}/scripts/File_Permission_Changes_Plus/logs/main.log
}

check_logs(){
if [ ! -d ${config_dir}/scripts/File_Permission_Changes_Plus/logs ]; then
    mkdir -p ${config_dir}/scripts/File_Permission_Changes_Plus/logs
    TEXT='创建日志文件夹成功'
    INFO
fi
if [ ! -f ${config_dir}/scripts/File_Permission_Changes_Plus/logs/main.log ]; then
    touch ${config_dir}/scripts/File_Permission_Changes_Plus/logs/main.log
    TEXT='创建主日志文件成功'
    INFO
fi
}

check_dir(){
# chown dir
find ${Media_DIR} \
    -type d \
    ! -group ${PGID} \
    -or \
    ! -user ${PUID} > ${config_dir}/scripts/File_Permission_Changes_Plus/logs/dir_changes_list.log

find ${Media_DIR} \
    -type d \
    ! -group ${PGID} \
    -or \
    ! -user ${PUID} \
    -exec chown ${PUID}:${PGID} {} \;
if [ $? -eq 0 ]; then
    TEXT='文件夹所属组设置成功'
    INFO
else
    TEXT='文件夹所属组设置失败'
    ERROR
    exit 1
fi

# chmod dir
find ${Media_DIR} \
    -type d \
    ! -perm ${CFVR} >> ${config_dir}/scripts/File_Permission_Changes_Plus/logs/dir_changes_list.log

find ${Media_DIR} \
    -type d \
    ! -perm ${CFVR} \
    -exec chmod ${CFVR} {} \;
if [ $? -eq 0 ]; then
    TEXT='文件夹访问权限设置成功'
    INFO
else
    TEXT='文件夹访问权限设置失败'
    ERROR
    exit 1
fi
}

check_file(){
# chown file
find ${Media_DIR} \
    -type f \
    ! -group ${PGID} \
    -or \
    ! -user ${PUID} > ${config_dir}/scripts/File_Permission_Changes_Plus/logs/file_changes_list.log

find ${Media_DIR} \
    -type f \
    ! -group ${PGID} \
    -or \
    ! -user ${PUID} \
    -exec chown ${PUID}:${PGID} {} \;
if [ $? -eq 0 ]; then
    TEXT='文件所属组设置成功'
    INFO
else
    TEXT='文件所属组设置失败'
    ERROR
    exit 1
fi

# chmod file
find ${Media_DIR} \
    -type f \
    ! -perm ${CFVR} >> ${config_dir}/scripts/File_Permission_Changes_Plus/logs/file_changes_list.log

find ${Media_DIR} \
    -type f \
    ! -perm ${CFVR} \
    -exec chmod ${CFVR} {} \;
if [ $? -eq 0 ]; then
    TEXT='文件访问权限设置成功'
    INFO
else
    TEXT='文件访问权限设置失败'
    ERROR
    exit 1
fi
}

main(){
check_logs
check_dir
check_file
}

main