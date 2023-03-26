#!/usr/bin/env bash

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
}
ERROR(){
echo -e "${Time} ${ERROR} ${1}"
}
WARN(){
echo -e "${Time} ${WARN} ${1}"
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

if ! which curl; then
    ERROR 'curl 未安装，请自行安装'
    exit 1
else
    INFO 'curl 已安装'
fi

for i in `seq -w 3 -1 0`
do
    echo -en "即将开始安装 ${Green}${i}${Font} \r"  
  sleep 1;
done

get_cron(){
echo -e "${Green}请输入Cron表达式（默认 */30 * * * * ）${Font}"
read -ep "CRON: " NEW_CRON
[[ -z "${NEW_CRON}" ]] && NEW_CRON="*/30 * * * *"
}

get_url(){
echo -e "${Green}请输入NAStool URL地址（http/https 一定要加）${Font}"
read -ep "NAStool URL: " NEW_URL
}

get_apikey(){
echo -e "${Green}请输入NAStool API Key${Font}"
read -ep "NAStool API Key: " NEW_APIKEY
}

sync_install(){
if crontab -l | grep -Eqi "/api/v1/sync/run"; then
    INFO '定时任务已存在'
    echo -e "${Green}是否重新设置定时任务 [Y/n]（默认 n ）${Font}"
    read -ep "Y/N:" YN
    [[ -z "${YN}" ]] && YN="n"
    if [[ ${YN} == [Yy] ]]; then
        (crontab -l | sed '/\/api\/v1\/sync\/run/d') | crontab -
        get_cron
        get_url
        get_apikey
        (crontab -l ; echo "${NEW_CRON} curl -X 'GET' '${NEW_URL}/api/v1/sync/run' -H 'accept: application/json' -H 'Authorization: ${NEW_APIKEY}' ") | crontab -
        if [ $? -eq 0 ]; then
            INFO '定时任务设置成功'
            crontab -l | grep -Ei "/api/v1/sync/run"
        else
            ERROR '定时任务设置失败'
            exit 1
        fi
    else
        exit 0
    fi
else
    get_cron
    get_url
    get_apikey
    (crontab -l ; echo "${NEW_CRON} curl -X 'GET' '${NEW_URL}/api/v1/sync/run' -H 'accept: application/json' -H 'Authorization: ${NEW_APIKEY}' ") | crontab -
    if [ $? -eq 0 ]; then
        INFO '定时任务设置成功'
        crontab -l | grep -Ei "/api/v1/sync/run"
    else
        ERROR '定时任务设置失败'
        exit 1
    fi
fi
}

sync_remove(){
if crontab -l | grep -Eqi "/api/v1/sync/run"; then
    echo -e "${Green}是否删除设置定时任务 [Y/n]（默认 n ）${Font}"
    read -ep "Y/N:" YN
    [[ -z "${YN}" ]] && YN="n"
    if [[ ${YN} == [Yy] ]]; then
        (crontab -l | sed '/\/api\/v1\/sync\/run/d') | crontab -
        if [ $? -eq 0 ]; then
            INFO '定时任务删除成功'
            crontab -l | grep -Ei "/api/v1/sync/run"
        else
            ERROR '定时任务删除失败'
            exit 1
        fi
    else
        exit 0
    fi
else
    WARN "定时任务不存在，删除失败"
fi
}

main(){
    clear
    echo -e "
——————————————————————————————————————————————————————————————————————————————————
 ____ _____ ____     ____                 
|  _ \_   _/ ___|   / ___|_ __ ___  _ __  
| | | || | \___ \  | |   | '__/ _ \| '_ \ 
| |_| || |  ___) | | |___| | | (_) | | | |
|____/ |_| |____/   \____|_|  \___/|_| |_|

Copyright (c) 2022 DDSRem <https://blog.ddsrem.com>

This is free software, licensed under the GNU General Public License.

——————————————————————————————————————————————————————————————————————————————————"
    echo -e "1、安装"
    echo -e "2、卸载"
    echo -e "3、退出脚本"
    echo -e "——————————————————————————————————————————————————————————————————————————————————"
    read -ep "请输入数字 [1-3]:" num
    case "$num" in
        1)
        clear
        sync_install
        ;;
        2)
        clear
        sync_remove
        ;;
        3)
        clear
        exit 0
        ;;
        *)
        clear
        ERROR '请输入正确数字 [1-4]'
        main
        ;;
        esac
}

main