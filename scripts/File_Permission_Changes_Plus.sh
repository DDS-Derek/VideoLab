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
WARN="[${Blue}WARN${Font}]"
Time=$(date +"%Y-%m-%d %T")

check_logs(){
if [ ! -d ./logs ]; then
    mkdir ./logs
fi
if [ ! -f ./logs/main.log ]; then
    touch ./logs/main.log
fi
}

check_dir(){
# chown dir
find ${Media_DIR} \
    -type d \
    ! -group ${PGID} \
    -or \
    ! -user ${PUID} > ./logs/dir_changes_list.log

find ${Media_DIR} \
    -type d \
    ! -group ${PGID} \
    -or \
    ! -user ${PUID} \
    -exec chown ${PUID}:${PGID} {} \;
if [ $? -eq 0 ]; then
    echo -e "${INFO} 文件夹所属组设置成功"
    echo -e "${Time} INFO 文件夹所属组设置成功" >> ./logs/main.log
else
    echo -e "${ERROR} 文件夹所属组设置失败"
    echo -e "${Time} ERROR 文件夹所属组设置失败" >> ./logs/main.log
    exit 1
fi

# chmod dir
find ${Media_DIR} \
    -type d \
    ! -perm ${CFVR} >> ./logs/dir_changes_list.log

find ${Media_DIR} \
    -type d \
    ! -perm ${CFVR} \
    -exec chmod ${CFVR} {} \;
if [ $? -eq 0 ]; then
    echo -e "${INFO} 文件夹访问权限设置成功"
    echo -e "${Time} INFO 文件夹访问权限设置成功" >> ./logs/main.log
else
    echo -e "${ERROR} 文件夹访问权限设置失败"
    echo -e "${Time} ERROR 文件夹访问权限设置失败" >> ./logs/main.log
    exit 1
fi
}

check_file(){
# chown file
find ${Media_DIR} \
    -type f \
    ! -group ${PGID} \
    -or \
    ! -user ${PUID} > ./logs/file_changes_list.log

find ${Media_DIR} \
    -type f \
    ! -group ${PGID} \
    -or \
    ! -user ${PUID} \
    -exec chown ${PUID}:${PGID} {} \;
if [ $? -eq 0 ]; then
    echo -e "${INFO} 文件所属组设置成功"
    echo -e "${Time} INFO 文件所属组设置成功" >> ./logs/main.log
else
    echo -e "${ERROR} 文件所属组设置失败"
    echo -e "${Time} ERROR 文件所属组设置失败" >> ./logs/main.log
    exit 1
fi

# chmod file
find ${Media_DIR} \
    -type f \
    ! -perm ${CFVR} >> ./logs/file_changes_list.log

find ${Media_DIR} \
    -type f \
    ! -perm ${CFVR} \
    -exec chmod ${CFVR} {} \;
if [ $? -eq 0 ]; then
    echo -e "${INFO} 文件访问权限设置成功"
    echo -e "${Time} INFO 文件访问权限设置成功" >> ./logs/main.log
else
    echo -e "${ERROR} 文件访问权限设置失败"
    echo -e "${Time} ERROR 文件访问权限设置失败" >> ./logs/main.log
    exit 1
fi
}

check_change(){
check_logs
check_dir
check_file
}

check_change