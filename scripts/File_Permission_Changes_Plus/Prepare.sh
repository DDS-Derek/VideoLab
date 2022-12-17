#!/usr/bin/env bash

. /etc/videolab/settings.sh
. ${config_dir}/nastools_all_in_one/basic_settings.sh

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

if [ ! -d ${config_dir}/scripts/File_Permission_Changes_Plus ]; then
    mkdir -p ${config_dir}/scripts/File_Permission_Changes_Plus
    TEXT='创建脚本文件夹成功' && INFO
else
    TEXT='脚本文件夹已存在' && INFO
fi
if [ ! -f ${config_dir}/scripts/File_Permission_Changes_Plus/File_Permission_Changes_Plus.sh ]; then
    curl -o \
        ${config_dir}/scripts/File_Permission_Changes_Plus/File_Permission_Changes_Plus.sh \
        https://ghproxy.com/https://raw.githubusercontent.com/DDS-Derek/VideoLab/master/scripts/File_Permission_Changes_Plus/File_Permission_Changes_Plus.sh
    if [ $? -eq 0 ]; then
        TEXT='下载File_Permission_Changes_Plus脚本成功' && INFO
        TEXT='测试脚本' && INFO
        /usr/bin/env bash ${config_dir}/scripts/File_Permission_Changes_Plus/File_Permission_Changes_Plus.sh
        if [ $? -eq 0 ]; then
            TEXT='测试成功' && INFO
        else
            TEXT='测试失败' && ERROR
            exit 1
        fi
    else
        TEXT='下载File_Permission_Changes_Plus脚本失败' && ERROR
        exit 1
    fi
else
    TEXT='File_Permission_Changes_Plus已存在' && INFO
fi

get_cron(){
echo -e "${Green}请输入Cron表达式（默认 */30 * * * * ）${Font}"
read -ep "CRON:" NEW_CRON
[[ -z "${NEW_CRON}" ]] && NEW_CRON="*/30 * * * *"
}

if crontab -l | grep -Eqi "File_Permission_Changes_Plus.sh"; then
    TEXT='定时任务已存在' && INFO
    echo -e "${Green}是否重新设置定时任务 [Y/n]（默认 n ）${Font}"
    read -ep "CRON:" YN
    [[ -z "${YN}" ]] && YN="n"
    if [[ ${YN} == [Yy] ]]; then
        (crontab -l | sed '/File_Permission_Changes_Plus.sh/d') | crontab -
        get_cron
        (crontab -l ; echo "${NEW_CRON} /usr/bin/env bash ${config_dir}/scripts/File_Permission_Changes_Plus/File_Permission_Changes_Plus.sh") | crontab -
        if [ $? -eq 0 ]; then
            TEXT='定时任务设置成功' && INFO
            crontab -l | grep -Ei "File_Permission_Changes_Plus.sh"
        else
            TEXT='定时任务设置失败' && ERROR
            exit 1
        fi
    else
        exit 0
    fi
else
    get_cron
    (crontab -l ; echo "${NEW_CRON} /usr/bin/env bash ${config_dir}/scripts/File_Permission_Changes_Plus/File_Permission_Changes_Plus.sh") | crontab -
    if [ $? -eq 0 ]; then
        TEXT='定时任务设置成功' && INFO
        crontab -l | grep -Ei "File_Permission_Changes_Plus.sh"
    else
        TEXT='定时任务设置失败' && ERROR
        exit 1
    fi
fi

exit 0
