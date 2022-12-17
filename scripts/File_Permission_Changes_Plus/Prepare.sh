#!/usr/bin/env bash

Blue="\033[34m"
Green="\033[32m"
Red="\033[31m"
Font="\033[0m"
INFO="[${Green}INFO${Font}]"
ERROR="[${Red}ERROR${Font}]"
Time=$(date +"%Y-%m-%d %T")
INFO(){
echo -e "${INFO} ${TEXT}"
}
ERROR(){
echo -e "${ERROR} ${TEXT}"
}

if ! which cron; then
    TEXT='Cron 未安装，请自行安装' && ERROR
    exit 1
else
    TEXT='Cron 已安装' && INFO
fi

if ! which crontab; then
    TEXT='Crontab 未安装，请自行安装' && ERROR
    exit 1
else
    TEXT='Crontab 已安装' && INFO
fi

. /etc/videolab/settings.sh
. ${config_dir}/nastools_all_in_one/basic_settings.sh

if [ ! -d ${config_dir}/scripts/File_Permission_Changes_Plus ]; then
    mkdir -p ${config_dir}/scripts/File_Permission_Changes_Plus
    TEXT='创建脚本文件夹成功' && INFO
fi
if [ ! -f ${config_dir}/scripts/File_Permission_Changes_Plus/File_Permission_Changes_Plus.sh ]; then
    curl -o ${config_dir}/scripts/File_Permission_Changes_Plus/File_Permission_Changes_Plus.sh https://ghproxy.com/
    TEXT='下载File_Permission_Changes_Plus脚本成功'
    INFO
fi