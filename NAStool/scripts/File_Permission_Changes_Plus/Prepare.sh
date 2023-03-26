#!/usr/bin/env bash

. /etc/videolab/settings.sh
. ${config_dir}/nastools_all_in_one/basic_settings.sh

Green="\033[32m"
Red="\033[31m"
Yellow='\033[33m'
Font="\033[0m"
INFO="[${Green}INFO${Font}]"
ERROR="[${Red}ERROR${Font}]"
WARN="[${Yellow}WARN${Font}]"
Time=$(date +"%Y-%m-%d %T")
INFO(){
echo -e "${Time} ${INFO} ${1}"
echo -e "${Time} INFO  ${1}" >> ${config_dir}/scripts/File_Permission_Changes_Plus/logs/main.log
}
ERROR(){
echo -e "${Time} ${ERROR} ${1}"
echo -e "${Time} ERROR  ${1}" >> ${config_dir}/scripts/File_Permission_Changes_Plus/logs/main.log
}
WARN(){
echo -e "${Time} ${WARN} ${1}"
echo -e "${Time} WARN  ${1}" >> ${config_dir}/scripts/File_Permission_Changes_Plus/logs/main.log
}

if ! which cron; then
    ERROR 'Cron 未安装，请自行安装'
    exit 1
else
    INFO 'Cron 已安装'
fi

if ! which crontab; then
    ERROR 'Crontab 未安装，请自行安装'
    exit 1
else
    INFO 'Crontab 已安装'
fi

if [ ! -d ${config_dir}/scripts/File_Permission_Changes_Plus ]; then
    mkdir -p ${config_dir}/scripts/File_Permission_Changes_Plus
    INFO '创建脚本文件夹成功'
else
    WARN '脚本文件夹已存在'
fi
if [ ! -f ${config_dir}/scripts/File_Permission_Changes_Plus/File_Permission_Changes_Plus.sh ]; then
    curl -o \
        ${config_dir}/scripts/File_Permission_Changes_Plus/File_Permission_Changes_Plus.sh \
        https://ghproxy.com/https://raw.githubusercontent.com/DDS-Derek/VideoLab/NAStool/scripts/File_Permission_Changes_Plus/File_Permission_Changes_Plus.sh
    if [ $? -eq 0 ]; then
        INFO '下载File_Permission_Changes_Plus脚本成功\n测试脚本'
        /usr/bin/env bash ${config_dir}/scripts/File_Permission_Changes_Plus/File_Permission_Changes_Plus.sh
        if [ $? -eq 0 ]; then
            INFO '测试成功'
        else
            ERROR '测试失败'
            exit 1
        fi
    else
        ERROR '下载File_Permission_Changes_Plus脚本失败'
        exit 1
    fi
else
    WARN 'File_Permission_Changes_Plus已存在'
fi

get_cron(){
echo -e "${Green}请输入Cron表达式（默认 */30 * * * * ）${Font}"
read -ep "CRON:" NEW_CRON
[[ -z "${NEW_CRON}" ]] && NEW_CRON="*/30 * * * *"
}

if crontab -l | grep -Eqi "File_Permission_Changes_Plus.sh"; then
    INFO '定时任务已存在'
    echo -e "${Green}是否重新设置定时任务 [Y/n]（默认 n ）${Font}"
    read -ep "CRON:" YN
    [[ -z "${YN}" ]] && YN="n"
    if [[ ${YN} == [Yy] ]]; then
        (crontab -l | sed '/File_Permission_Changes_Plus.sh/d') | crontab -
        get_cron
        (crontab -l ; echo "${NEW_CRON} /usr/bin/env bash ${config_dir}/scripts/File_Permission_Changes_Plus/File_Permission_Changes_Plus.sh") | crontab -
        if [ $? -eq 0 ]; then
            INFO '定时任务设置成功'
            crontab -l | grep -Ei "File_Permission_Changes_Plus.sh"
        else
            ERROR '定时任务设置失败'
            exit 1
        fi
    else
        exit 0
    fi
else
    get_cron
    (crontab -l ; echo "${NEW_CRON} /usr/bin/env bash ${config_dir}/scripts/File_Permission_Changes_Plus/File_Permission_Changes_Plus.sh") | crontab -
    if [ $? -eq 0 ]; then
        INFO '定时任务设置成功'
        crontab -l | grep -Ei "File_Permission_Changes_Plus.sh"
    else
        ERROR '定时任务设置失败'
        exit 1
    fi
fi

exit 0
