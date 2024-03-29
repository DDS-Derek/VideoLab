#!/usr/bin/env bash

#  _   _    _    ____  _              _ 
# | \ | |  / \  / ___|| |_ ___   ___ | |
# |  \| | / _ \ \___ \| __/ _ \ / _ \| |
# | |\  |/ ___ \ ___) | || (_) | (_) | |
# |_| \_/_/   \_\____/ \__\___/ \___/|_|
#
# Copyright (c) 2022 DDSRem <https://blog.ddsrem.com>
#
# This is free software, licensed under the GNU General Public License.
#
BUILD_TIME=2023-1-20


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

#root权限
root_need(){
    if [[ $EUID -ne 0 ]]; then
        TEXT='此脚本必须以 root 身份运行！' && ERROR
        exit 1
    fi
}

dsm_ipkg_install(){
TEXT='正在安装IPKG中...' && INFO
wget http://ipkg.nslu2-linux.org/feeds/optware/syno-i686/cross/unstable/syno-i686-bootstrap_1.2-7_i686.xsh
chmod +x syno-i686-bootstrap_1.2-7_i686.xsh
sh syno-i686-bootstrap_1.2-7_i686.xsh
if [ $? -eq 0 ]; then
    TEXT='IPKG安装成功' && INFO
else
    TEXT='IPKG安装失败' && ERROR
    exit 1
fi
}

# 软件包安装
package_installation(){
    _os=`uname`
    echo -e "${Blue}use system: ${_os}${Font}"
    if [ ${_os} == "Darwin" ]; then
        OSNAME='macos'
        TEXT='此系统无法使用此脚本' && ERROR
        exit 1
    elif [ -f /etc/VERSION ]; then
        OSNAME='dsm'
        if ! which ipkg; then
            dsm_ipkg_install
        else
            TEXT='IPKG 已安装' && INFO
        fi
        ipkg update
        if ! which lsof; then
            ipkg install lsof
        fi
        if ! which unzip; then
            ipkg install unzip
        fi
    elif [ -f /etc/openwrt_release ]; then
        OSNAME='OpenWRT'
        if ! which wget; then
            TEXT="未安装wget，请手动安装" && ERROR
            exit 1
        fi
        if ! which unzip; then
            TEXT="未安装unzip，请手动安装" && ERROR
            exit 1
        fi
        if ! which curl; then
            TEXT="未安装curl，请手动安装" && ERROR
            exit 1
        fi
        if ! which lsof; then
            TEXT="未安装lsof，请手动安装" && ERROR
            exit 1
        fi
        sleep 2
    elif grep -Eqi "QNAP" /etc/issue; then
        OSNAME='QNAP'
    elif grep -Eq "openSUSE" /etc/*-release; then
        OSNAME='opensuse'
        zypper refresh
        zypper -n install wget zip unzip curl lsof
    elif grep -Eq "FreeBSD" /etc/*-release; then
        OSNAME='freebsd'
        TEXT='此系统无法使用此脚本' && ERROR
        exit 1
    elif grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        OSNAME='centos'
        yum install -y wget zip unzip curl lsof
    elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
        OSNAME='fedora'
        yum install -y wget zip unzip curl lsof
    elif grep -Eqi "Rocky" /etc/issue || grep -Eq "Rocky" /etc/*-release; then
        OSNAME='rocky'
        yum install -y wget zip unzip curl lsof
    elif grep -Eqi "AlmaLinux" /etc/issue || grep -Eq "AlmaLinux" /etc/*-release; then
        OSNAME='alma'
        yum install -y wget zip unzip curl lsof
    elif grep -Eqi "Amazon Linux" /etc/issue || grep -Eq "Amazon Linux" /etc/*-release; then
        OSNAME='amazon'
        yum install -y wget zip unzip curl lsof
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        OSNAME='debian'
        apt update -y
        apt install -y devscripts
        apt install -y wget zip unzip curl lsof
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        OSNAME='ubuntu'
        apt install -y wget zip unzip curl lsof
    elif grep -Eqi "Alpine" /etc/issue || grep -Eq "Alpine" /etc/*-release; then
        OSNAME='alpine'
        apk add wget zip unzip curl lsof
    else
        OSNAME='unknow'
        TEXT='此系统无法使用此脚本' && ERROR
        exit 1
    fi
}

port_if(){
# 0 未被占用
# 1 被占用
TEST_PORT_i=$(lsof -i :${TEST_PORT}|grep -v "PID" | awk '{print $2}')
if [ "$TEST_PORT_i" != "" ]; then
   TEST_PORT_IF=1
else
   TEST_PORT_IF=0
fi
}

manual_update_containers(){
clear
echo -e "${Blue}更新容器${Font}"
docker ps --all --format "table {{.Names}}"
if [ $? -eq 0 ]; then
    echo -e "${Green}请输入你想更新的容器名（可以输入多个容器名，中间用空格分离）${Font}"
    read -ep "Containers Name:" containers_name
    clear
    echo -e "${Green}本次更新容器列表${Font}\n${containers_name}"
    sleep 1
    for i in `seq -w 3 -1 0`
    do
        echo -en "${Green}即将开始更新${Font}${Blue} $i ${Font}\r"  
    sleep 1;
    done
    docker run --rm \
        -v /var/run/docker.sock:/var/run/docker.sock \
        containrrr/watchtower \
        --run-once \
        --cleanup \
        ${containers_name}
    if [ $? -eq 0 ]; then
        TEXT='更新成功' && INFO
    else
        TEXT='更新失败，请重新尝试' && ERROR
        exit 1
    fi
else
    TEXT='列出所有容器失败，无法继续更新' && ERROR
    exit 1
fi
}

timing_update_containers(){
clear
if [[ "$(docker inspect videolab-watchtower 2> /dev/null | grep '"Name": "/videolab-watchtower"')" = "" ]]; then
    echo -e "${Blue}设置定时更新容器${Font}"
    docker ps --all --format "table {{.Names}}"
    if [ $? -eq 0 ]; then
        echo -e "${Green}请输入你想定时更新的容器名（可以输入多个容器名，中间用空格分离）${Font}"
        read -ep "Containers Name:" containers_name
        clear
        echo -e "${Green}需定时更新容器列表${Font}\n${containers_name}"
        for i in `seq -w 3 -1 0`
        do
            echo -en "${Green}即将开始启动定时任务${Font}${Blue} $i ${Font}\r"  
        sleep 1;
        done
        docker run -itd \
            --name videolab-watchtower \
            -e TZ=Asia/Shanghai \
            --restart always \
            -v /var/run/docker.sock:/var/run/docker.sock \
            containrrr/watchtower \
            --cleanup ${containers_name} --schedule "0 0 0 * * *"
        if [ $? -eq 0 ]; then
            TEXT='定时任务设置成功' && INFO
        else
            TEXT='定时任务设置失败，请重新尝试' && ERROR
            exit 1
        fi
    else
        TEXT='列出所有容器失败，无法继续更新' && ERROR
        exit 1
    fi
else
    echo -e "${Blue}设置定时更新容器${Font}"
    echo -e "${Green}检测到旧定时任务，清理旧定时任务中...${Font}"
    docker stop videolab-watchtower
    if [ $? -eq 0 ]; then
        TEXT='停止旧定时任务成功' && INFO
    else
        TEXT='停止旧容器失败，请尝试手动停止 videolab-watchtower 容器' && ERROR
        exit 1
    fi
    docker rm -f videolab-watchtower
    if [ $? -eq 0 ]; then
        TEXT='删除旧定时任务成功' && INFO
    else
        TEXT='删除旧容器失败，请尝试手动删除 videolab-watchtower 容器' && ERROR
        exit 1
    fi
    docker ps --all --format "table {{.Names}}"
    if [ $? -eq 0 ]; then
        echo -e "${Green}请输入你想定时更新的容器名（可以输入多个容器名，中间用空格分离）${Font}"
        read -ep "Containers Name:" containers_name
        clear
        echo -e "${Green}需定时更新容器列表${Font}\n${containers_name}"
        for i in `seq -w 3 -1 0`
        do
            echo -en "${Green}即将开始启动定时任务${Font}${Blue} $i ${Font}\r"  
        sleep 1;
        done
        docker run -itd \
            --name videolab-watchtower \
            -e TZ=Asia/Shanghai \
            --restart always \
            -v /var/run/docker.sock:/var/run/docker.sock \
            containrrr/watchtower \
            --cleanup ${containers_name} --schedule "0 0 0 * * *"
        if [ $? -eq 0 ]; then
            TEXT='定时任务设置成功' && INFO
        else
            TEXT='定时任务设置失败，请重新尝试' && ERROR
            exit 1
        fi
    else
        TEXT='列出所有容器失败，无法继续更新' && ERROR
        exit 1
    fi
fi
}

update_containers(){
    echo -e "${Blue}更新${Font}\n"
    echo -e "——————————————————————————————————————————————————————————————————————————————————"
    echo -e "1、手动更新"
    echo -e "2、设置定时更新"
    echo -e "3、返回上级目录"
    echo -e "——————————————————————————————————————————————————————————————————————————————————"
    read -ep "请输入数字 [1-3]:" num
    case "$num" in
    1)
    manual_update_containers
    ;;
    2)
    timing_update_containers
    ;;
    3)
    clear
    main_return
    ;;
    *)
    clear
    TEXT='请输入正确数字 [1-3]' && ERROR
    update_containers
    ;;
    esac
}

get_PUID(){
echo -e "${Green}请输入媒体文件所有者的用户ID（默认 0 ）${Font}"
read -ep "PUID:" NEW_PUID
[[ -z "${NEW_PUID}" ]] && NEW_PUID="0"
}
get_PGID(){
echo -e "${Green}请输入媒体文件所有者的用户组ID（默认 0 ）${Font}"
read -ep "PGID:" NEW_PGID
[[ -z "${NEW_PGID}" ]] && NEW_PGID="0"
}
get_id(){
echo -e "${Blue}容器用户和用户组ID设置${Font}"
echo -e "前往 https://github.com/jxxghp/nas-tools/tree/master/docker#%E5%85%B3%E4%BA%8Epuidpgid%E7%9A%84%E8%AF%B4%E6%98%8E 查看uid获取方法\n"
get_PUID
echo
get_PGID
}
get_umask(){
echo -e "${Blue}容器Umask设置${Font}\n"
echo -e "${Green}请输入Umask（默认 000 ）${Font}"
read -ep "Umask:" NEW_UMASK
[[ -z "${NEW_UMASK}" ]] && NEW_UMASK="000"
}
get_CFVR(){
echo -e "${Blue}CFVR设置${Font}\n"
echo -e "${Green}请输入CFVR（默认 755 ）${Font}"
read -ep "CFVR:" NEW_CFVR
[[ -z "${NEW_CFVR}" ]] && NEW_CFVR="755"
}
get_tz(){
echo -e "${Blue}容器时区设置${Font}\n"
echo -e "${Green}请输入时区（默认 Asia/Shanghai ）${Font}"
read -ep "TZ:" NEW_TZ
[[ -z "${NEW_TZ}" ]] && NEW_TZ="Asia/Shanghai"
}
get_config_dir(){
echo -e "${Blue}文件路径设置${Font}\n"
echo -e "${Green}请输入配置文件存放路径（默认 /root/data ）${Font}"
read -ep "DIR:" NEW_config_dir
[[ -z "${NEW_config_dir}" ]] && NEW_config_dir="/root/data"
echo 
}
get_download_dir(){
echo -e "${Green}请输入下载目录路径（默认 /media/downloads ）${Font}"
echo -e "${Red}注意，下载目录路径应在媒体目录文件夹下\n比如说媒体路径为/media，那么下载路径应填/media/downloads${Font}"
read -ep "DIR:" NEW_download_dir
[[ -z "${NEW_download_dir}" ]] && NEW_download_dir="/media/downloads"
echo 
}
get_media_dir(){
echo -e "${Green}请输入媒体路径（默认 /media ）${Font}"
echo -e "${Red}注意，下载目录路径应在媒体目录文件夹下\n比如说媒体路径为/media，那么下载路径应填/media/downloads${Font}"
read -ep "DIR:" NEW_media_dir
[[ -z "${NEW_media_dir}" ]] && NEW_media_dir="/media"
echo 
}
choose_docker_install_model(){
    echo -e "${Blue}容器安装模式选择${Font}\n"
    echo -e "——————————————————————————————————————————————————————————————————————————————————"
    echo -e "1、docker-cli安装模式"
    echo -e "2、docker-compose安装模式"
    echo -e "——————————————————————————————————————————————————————————————————————————————————"
    read -ep "请输入数字 [1-2]:" num
    case "$num" in
    1)
    NEW_docker_install_model=cli
    ;;
    2)
    NEW_docker_install_model=compose
    ;;
    *)
    clear
    TEXT='请输入正确数字 [1-2]' && ERROR
    choose_docker_install_model
    ;;
    esac
}
save_basic_settings(){
if [ ! -d ${NEW_config_dir} ]; then
    mkdir -p ${NEW_config_dir}
fi
if [ ! -d ${NEW_config_dir}/nastools_all_in_one ]; then
    mkdir -p ${NEW_config_dir}/nastools_all_in_one
fi
if [ ! -d ${NEW_download_dir} ]; then
    mkdir -p ${NEW_download_dir}
fi
if [ ! -d ${NEW_media_dir} ]; then
    mkdir -p ${NEW_media_dir}
fi
if [ ! -d /etc/videolab ]; then
    # 旧配置兼容
    if [ -d /etc/nastools_all_in_one ]; then
        mv /etc/nastools_all_in_one /etc/videolab
    else
        mkdir -p /etc/videolab
    fi
fi
if [ ! -f ${NEW_config_dir}/nastools_all_in_one ]; then
    touch ${NEW_config_dir}/nastools_all_in_one/basic_settings.sh
fi
if [ ! -f /etc/videolab/settings.sh ]; then
    touch /etc/videolab/settings.sh
fi
cat > ${NEW_config_dir}/nastools_all_in_one/basic_settings.sh << EOF
#!/usr/bin/env bash

PUID=${NEW_PUID}
PGID=${NEW_PGID}
Umask=${NEW_UMASK}
CFVR=${NEW_CFVR}

TZ=${NEW_TZ}

download_dir=${NEW_download_dir}
media_dir=${NEW_media_dir}

docker_install_model=${NEW_docker_install_model}

EOF
cat > /etc/videolab/settings.sh << EOF
#!/usr/bin/env bash

config_dir=${NEW_config_dir}

EOF

#. /etc/videolab/settings.sh
#. ${config_dir}/nastools_all_in_one/basic_settings.sh

if [ $? -eq 0 ]; then
    TEXT='保存成功' && INFO
fi
}
show_basic_settings(){
    echo -e "${Blue}基础设置总览${Font}\n"
    echo -e "${Green}PUID=${NEW_PUID}${Font}"
    echo -e "${Green}PGID=${NEW_PGID}${Font}"
    echo -e "${Green}Umask=${NEW_UMASK}${Font}"
    echo -e "${Green}CFVR=${NEW_CFVR}${Font}"
    echo -e "${Green}TZ=${NEW_TZ}${Font}"
    echo -e "${Green}配置文件存放路径 ${NEW_config_dir}${Font}"
    echo -e "${Green}下载目录路径 ${NEW_download_dir}${Font}"
    echo -e "${Green}媒体最终存放路径 ${NEW_media_dir}${Font}"
    echo -e "${Green}容器安装模式docker-${NEW_docker_install_model}${Font}\n"
    echo -e "——————————————————————————————————————————————————————————————————————————————————"
    echo -e "1、修改PUID"
    echo -e "2、修改PGID"
    echo -e "3、修改Umask"
    echo -e "4、修改CFVR"
    echo -e "5、修改时区"
    echo -e "6、修改配置文件存放路径"
    echo -e "7、修改媒体存放路径"
    echo -e "8、修改下载目录路径"
    echo -e "9、修改容器安装模式选择"
    echo -e "10、保存配置"
    echo -e "——————————————————————————————————————————————————————————————————————————————————"
    read -ep "请输入数字 [1-10]:" num
    case "$num" in
        1)
        get_PUID
        clear
        show_basic_settings
        ;;
        2)
        get_PGID
        clear
        show_basic_settings
        ;;
        3)
        get_umask
        clear
        show_basic_settings
        ;;
        4)
        get_CFVR
        clear
        show_basic_settings
        ;;
        5)
        get_tz
        clear
        show_basic_settings
        ;;
        6)
        get_config_dir
        clear
        show_basic_settings
        ;;
        7)
        get_media_dir
        clear
        show_basic_settings
        ;;
        8)
        get_download_dir
        clear
        show_basic_settings
        ;;
        9)
        choose_docker_install_model
        clear
        show_basic_settings
        ;;
        10)
        save_basic_settings
        clear
        ;;
        *)
        clear
        TEXT='请输入正确数字 [1-10]' && ERROR
        show_basic_settings
        ;;
        esac
}

fix_basic_settings(){
clear
if [ ! -f /etc/videolab/settings.sh ]; then
    get_id
    clear
    get_umask
    clear
    get_CFVR
    clear
    get_tz
    clear
    get_config_dir
    get_media_dir
    get_download_dir
    clear
    choose_docker_install_model
    clear
    show_basic_settings
else
    . /etc/videolab/settings.sh
    . ${config_dir}/nastools_all_in_one/basic_settings.sh
    Old_PUID=${PUID}
    Old_PGID=${PGID}
    Old_Umask=${Umask}
    Old_CFVR=${CFVR}
    Old_TZ=${TZ}
    Old_download_dir=${download_dir}
    Old_media_dir=${media_dir}
    Old_config_dir=${config_dir}
    Old_docker_install_model=${docker_install_model}

    NEW_PUID=${Old_PUID}
    NEW_PGID=${Old_PGID}
    NEW_UMASK=${Old_Umask}
    NEW_CFVR=${Old_CFVR}
    NEW_TZ=${Old_TZ}
    NEW_download_dir=${Old_download_dir}
    NEW_media_dir=${Old_media_dir}
    NEW_config_dir=${Old_config_dir}
    NEW_docker_install_model=${Old_docker_install_model}
    show_basic_settings
fi
}

get_container_name(){
echo -e "${Green}请输入容器名称${Font}"
read -ep "NAME:" container_name
TEXT='设置成功！' && INFO
}

get_nastool_port(){
echo -e "${Green}请输入NAStool Web 访问端口（默认 3000 ）${Font}"
read -ep "PORT:" NAStool_port
[[ -z "${NAStool_port}" ]] && NAStool_port="3000"
TEST_PORT=${NAStool_port}
port_if
if [[ ${TEST_PORT_IF=} = '1' ]]; then
    TEXT='端口被占用，请重新输入新端口' && ERROR
    get_nastool_port
else
    TEXT='设置成功！' && INFO
fi
}
get_nastool_update(){
echo -e "${Green}是否启用重启更新 [Y/n]（默认 n ）${Font}"
read -ep "UPDATE:" NAStool_update
[[ -z "${NAStool_update}" ]] && NAStool_update="n"
if [[ ${NAStool_update} == [Yy] ]]; then
NAStool_update_eld=true
fi
if [[ ${NAStool_update} == [Nn] ]]; then
NAStool_update_eld=false
fi
TEXT='设置成功！' && INFO
}
nastool_install(){
clear
echo -e "${Blue}NAStool 安装${Font}\n"
get_container_name
get_nastool_port
get_nastool_update
sleep 2

. /etc/videolab/settings.sh
. ${config_dir}/nastools_all_in_one/basic_settings.sh
if [ ! -d ${config_dir}/nas-tools ]; then
    mkdir -p ${config_dir}/nas-tools
fi
if [ ! -d ${config_dir}/nas-tools/config ]; then
    mkdir -p ${config_dir}/nas-tools/config
fi
if [[ ${docker_install_model} = 'compose' ]]; then
    clear
    if [ ! -f ${config_dir}/nas-tools/docker-compose.yaml ]; then
        touch ${config_dir}/nas-tools/docker-compose.yaml
    fi
    cat > ${config_dir}/nas-tools/docker-compose.yaml << EOF
version: "3"
services:
  nas-tools:
    image: jxxghp/nas-tools:latest
    ports:
      - ${NAStool_port}:3000
    volumes:
      - ${config_dir}/nas-tools/config:/config
      - ${media_dir}:/media
    environment: 
      - PUID=${PUID}
      - PGID=${PGID}
      - UMASK=${Umask}
      - NASTOOL_AUTO_UPDATE=${NAStool_update_eld}
     #- REPO_URL=https://ghproxy.com/https://github.com/jxxghp/nas-tools.git
    restart: always
    network_mode: bridge
    hostname: ${container_name}
    container_name: ${container_name}
EOF
    cd ${config_dir}/nas-tools
    docker-compose up -d
    if [ $? -eq 0 ]; then
        TEXT='NAStools 安装成功' && INFO
    else
        TEXT='NAStools 安装失败，请尝试重新运行脚本' && ERROR
        exit 1
    fi
fi
if [[ ${docker_install_model} = 'cli' ]]; then
    clear
    docker run -d \
        --name ${container_name} \
        --hostname ${container_name} \
        -p ${NAStool_port}:3000\
        -v ${config_dir}/nas-tools/config:/config \
        -v ${media_dir}:/media \
        -e PUID=${PUID} \
        -e PGID=${PGID} \
        -e UMASK=${Umask} \
        -e NASTOOL_AUTO_UPDATE=${NAStool_update_eld} \
        --restart always \
        jxxghp/nas-tools:latest
    if [ $? -eq 0 ]; then
        TEXT='NAStools 安装成功' && INFO
    else
        TEXT='NAStools 安装失败，请尝试重新运行脚本' && ERROR
        exit 1
    fi
fi
}


choose_downloader(){
    echo -e "${Blue}选择安装下载器${Font}\n"
    echo -e "——————————————————————————————————————————————————————————————————————————————————"
    echo -e "1、Transmission"
    echo -e "2、qBittorrent"
    echo -e "3、Aria2-Pro"
    echo -e "4、Transmission快验版"
    echo -e "5、qBittorrent快验版"
    echo -e "6、跳过下载器安装部分"
    echo -e "——————————————————————————————————————————————————————————————————————————————————"
    read -ep "请输入数字 [1-6]:" num
    case "$num" in
    1)
    the_downloader_install=tr
    ;;
    2)
    the_downloader_install=qb
    ;;
    3)
    the_downloader_install=aria2
    ;;
    4)
    the_downloader_install=tr_sk
    ;;
    5)
    the_downloader_install=qb_sk
    ;;
    6)
    the_downloader_install=false
    ;;
    *)
    clear
    TEXT='请输入正确数字 [1-6]' && ERROR
    choose_downloader
    ;;
    esac
}

tr_web_port(){
echo -e "${Green}请输入Transmission Web 访问端口（默认 9091 ）${Font}"
read -ep "PORT:" tr_port
[[ -z "${tr_port}" ]] && tr_port="9091"
TEST_PORT=${tr_port}
port_if
if [[ ${TEST_PORT_IF=} = '1' ]]; then
    TEXT='端口被占用，请重新输入新端口' && ERROR
    tr_web_port
else
    TEXT='设置成功！' && INFO
fi
echo
}
tr_port_torrent_i(){
echo -e "${Green}请输入Transmission Torrent 端口（默认 51413 ）${Font}"
read -ep "PORT:" tr_port_torrent 
[[ -z "${tr_port_torrent}" ]] && tr_port_torrent="51413"
TEST_PORT=${tr_port_torrent}
port_if
if [[ ${TEST_PORT_IF=} = '1' ]]; then
    TEXT='端口被占用，请重新输入新端口' && ERROR
    tr_port_torrent_i
else
    TEXT='设置成功！' && INFO
fi
echo
}
tr_install(){
clear
echo -e "${Blue}Transmission 安装${Font}\n"
get_container_name
tr_web_port
tr_port_torrent_i
echo -e "${Green}请输入Transmission Web 用户名（默认 username ）${Font}"
read -ep "USERNAME:" tr_username
[[ -z "${tr_username}" ]] && tr_username="username"
TEXT='设置成功！' && INFO
echo
echo -e "${Green}请输入Transmission Web 密码（默认 password ）${Font}"
read -ep "PASSWORD:" tr_password
[[ -z "${tr_password}" ]] && tr_password="password"
TEXT='设置成功！' && INFO
sleep 2

clear
echo -e "${Blue}设置总览${Font}\n"
echo -e "${Green}Transmission Web 访问端口=${tr_port}${Font}"
echo -e "${Green}Transmission Torrent 端口=${tr_port_torrent}${Font}"
echo -e "${Green}Transmission Web 用户名=${tr_username}${Font}"
echo -e "${Green}Transmission Web 密码=${tr_password}${Font}\n"
for i in `seq -w 10 -1 0`
do
    echo -en "${Green}即将开始安装${Font}${Blue} $i ${Font}\r"  
  sleep 1;
done

if [ ! -d ${config_dir}/transmission ]; then
    mkdir -p ${config_dir}/transmission
fi
if [ ! -d ${config_dir}/transmission/config ]; then
    mkdir -p ${config_dir}/transmission/config
fi
chown -R ${PUID}:${PGID} ${config_dir}/transmission
if [[ ${docker_install_model} = 'compose' ]]; then
    clear
    if [ ! -f ${config_dir}/transmission/docker-compose.yaml ]; then
        touch ${config_dir}/transmission/docker-compose.yaml
    fi
    cat > ${config_dir}/transmission/docker-compose.yaml << EOF
version: "2.1"
services:
  transmission:
    image: ddsderek/videolab:transmission-${BUILD_TIME}
    container_name: ${container_name}
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
      - TRANSMISSION_WEB_HOME=/transmission-web-control/
      - USER=${tr_username}
      - PASS=${tr_password}
      - DOWNLOAD_DIR=/downloads
      - PEERPORT=${tr_port_torrent}
    volumes:
      - ${config_dir}/transmission/config:/config
      - ${download_dir}:/downloads
    ports:
      - ${tr_port}:9091
      - ${tr_port_torrent}:${tr_port_torrent}
      - ${tr_port_torrent}:${tr_port_torrent}/udp
    restart: always
EOF
    cd ${config_dir}/transmission
    docker-compose up -d
    if [ $? -eq 0 ]; then
        TEXT='Transmission 安装成功' && INFO
    else
        TEXT='Transmission 安装失败，请尝试重新运行脚本' && ERROR
    fi
fi

if [[ ${docker_install_model} = 'cli' ]]; then
    docker run -d \
    --name=${container_name} \
    -e PUID=${PUID} \
    -e PGID=${PGID} \
    -e TZ=${TZ} \
    -e TRANSMISSION_WEB_HOME=/transmission-web-control/ \
    -e USER=${tr_username} \
    -e PASS=${tr_password} \
    -e PEERPORT=${tr_port_torrent} \
    -e DOWNLOAD_DIR=/downloads \
    -p ${tr_port}:9091 \
    -p ${tr_port_torrent}:${tr_port_torrent} \
    -p ${tr_port_torrent}:${tr_port_torrent}/udp \
    -v ${config_dir}/transmission/config:/config \
    -v ${download_dir}:/downloads \
    --restart always \
    ddsderek/videolab:transmission-${BUILD_TIME}
    if [ $? -eq 0 ]; then
        TEXT='Transmission 安装成功' && INFO
    else
        TEXT='Transmission 安装失败，请尝试重新运行脚本' && ERROR
    fi
fi
}

tr_sk_install(){
clear
echo -e "${Blue}Transmission Skip Patch 安装${Font}\n"
get_container_name
tr_web_port
tr_port_torrent_i
echo -e "${Green}请输入Transmission Web 用户名（默认 username ）${Font}"
read -ep "USERNAME:" tr_username
[[ -z "${tr_username}" ]] && tr_username="username"
TEXT='设置成功！' && INFO
echo
echo -e "${Green}请输入Transmission Web 密码（默认 password ）${Font}"
read -ep "PASSWORD:" tr_password
[[ -z "${tr_password}" ]] && tr_password="password"
TEXT='设置成功！' && INFO
sleep 2

clear
echo -e "${Blue}设置总览${Font}\n"
echo -e "${Green}Transmission Web 访问端口=${tr_port}${Font}"
echo -e "${Green}Transmission Torrent 端口=${tr_port_torrent}${Font}"
echo -e "${Green}Transmission Web 用户名=${tr_username}${Font}"
echo -e "${Green}Transmission Web 密码=${tr_password}${Font}\n"
for i in `seq -w 10 -1 0`
do
    echo -en "${Green}即将开始安装${Font}${Blue} $i ${Font}\r"  
  sleep 1;
done

if [ ! -d ${config_dir}/transmission_sk ]; then
    mkdir -p ${config_dir}/transmission_sk
fi
if [ ! -d ${config_dir}/transmission_sk/config ]; then
    mkdir -p ${config_dir}/transmission_sk/config
fi
chown -R ${PUID}:${PGID} ${config_dir}/transmission_sk
if [[ ${docker_install_model} = 'compose' ]]; then
    clear
    if [ ! -f ${config_dir}/transmission_sk/docker-compose.yaml ]; then
        touch ${config_dir}/transmission_sk/docker-compose.yaml
    fi
    cat > ${config_dir}/transmission_sk/docker-compose.yaml << EOF
version: "2.1"
services:
  transmission_sk:
    image: ddsderek/videolab:transmission_skip_patch-${BUILD_TIME}
    container_name: ${container_name}
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
      - TRANSMISSION_WEB_HOME=/transmission-web-control/
      - USER=${tr_username}
      - PASS=${tr_password}
      - DOWNLOAD_DIR=/downloads
      - PEERPORT=${tr_port_torrent}
    volumes:
      - ${config_dir}/transmission_sk/config:/config
      - ${download_dir}:/downloads
    ports:
      - ${tr_port}:9091
      - ${tr_port_torrent}:${tr_port_torrent}
      - ${tr_port_torrent}:${tr_port_torrent}/udp
    restart: always
EOF
    cd ${config_dir}/transmission_sk
    docker-compose up -d
    if [ $? -eq 0 ]; then
        TEXT='Transmission Skip Patch 安装成功' && INFO
    else
        TEXT='Transmission Skip Patch 安装失败，请尝试重新运行脚本' && ERROR
        exit 1
    fi
fi

if [[ ${docker_install_model} = 'cli' ]]; then
    docker run -d \
    --name=${container_name} \
    -e PUID=${PUID} \
    -e PGID=${PGID} \
    -e TZ=${TZ} \
    -e TRANSMISSION_WEB_HOME=/transmission-web-control/ \
    -e USER=${tr_username} \
    -e PASS=${tr_password} \
    -e PEERPORT=${tr_port_torrent} \
    -e DOWNLOAD_DIR=/downloads \
    -p ${tr_port}:9091 \
    -p ${tr_port_torrent}:${tr_port_torrent} \
    -p ${tr_port_torrent}:${tr_port_torrent}/udp \
    -v ${config_dir}/transmission_sk/config:/config \
    -v ${download_dir}:/downloads \
    --restart always \
    ddsderek/videolab:transmission_skip_patch-${BUILD_TIME}
    if [ $? -eq 0 ]; then
        TEXT='Transmission Skip Patch 安装成功' && INFO
    else
        TEXT='Transmission Skip Patch 安装失败，请尝试重新运行脚本' && ERROR
        exit 1
    fi
fi
}

qb_web_port(){
echo -e "${Green}请输入qBittorrent Web 访问端口（默认 8080 ）${Font}"
read -ep "PORT:" qb_port
[[ -z "${qb_port}" ]] && qb_port="8080"
TEST_PORT=${qb_port}
port_if
if [[ ${TEST_PORT_IF=} = '1' ]]; then
    TEXT='端口被占用，请重新输入新端口' && ERROR
    qb_web_port
else
    TEXT='设置成功！' && INFO
fi
echo
}
qb_port_torrent_i(){
echo -e "${Green}请输入qBittorrent Torrent 端口（默认 34567 ）${Font}"
read -ep "PORT:" qb_port_torrent 
[[ -z "${qb_port_torrent}" ]] && qb_port_torrent="34567"
TEST_PORT=${qb_port_torrent}
port_if
if [[ ${TEST_PORT_IF=} = '1' ]]; then
    TEXT='端口被占用，请重新输入新端口' && ERROR
    qb_port_torrent_i
else
    TEXT='设置成功！' && INFO
fi
echo
}
qb_install(){
clear
echo -e "${Blue}qBittorrent 安装${Font}\n"
get_container_name
qb_web_port
qb_port_torrent_i
sleep 2

clear
echo -e "${Blue}设置总览${Font}\n"
echo -e "${Green}qBittorrent Web 访问端口=${qb_port}${Font}"
echo -e "${Green}qBittorrent Torrent 端口=${qb_port_torrent}${Font}\n"
for i in `seq -w 5 -1 0`
do
    echo -en "${Green}即将开始安装${Font}${Blue} $i ${Font}\r"  
  sleep 1;
done

if [ ! -d ${config_dir}/qbittorrent ]; then
    mkdir -p ${config_dir}/qbittorrent
fi
if [ ! -d ${config_dir}/qbittorrent/config ]; then
    mkdir -p ${config_dir}/qbittorrent/config
fi
chown -R ${PUID}:${PGID} ${config_dir}/qbittorrent
if [[ ${docker_install_model} = 'compose' ]]; then
    clear
    if [ ! -f ${config_dir}/qbittorrent/docker-compose.yaml ]; then
        touch ${config_dir}/qbittorrent/docker-compose.yaml
    fi
    cat > ${config_dir}/qbittorrent/docker-compose.yaml << EOF
version: "2.0"
services:
  qbittorrent:
    image: ddsderek/videolab:qbittorrent-${BUILD_TIME}
    container_name: ${container_name}
    restart: always
    tty: true
    network_mode: bridge
    hostname: ${container_name}
    volumes:
      - ${config_dir}/qbittorrent/config:/data
      - ${download_dir}:/downloads
    tmpfs:
      - /tmp
    environment:
      - WEBUI_PORT=${qb_port}
      - BT_PORT=${qb_port_torrent}
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    ports:
      - ${qb_port}:${qb_port}
      - ${qb_port_torrent}:${qb_port_torrent}
      - ${qb_port_torrent}:${qb_port_torrent}/udp
EOF
    cd ${config_dir}/qbittorrent
    docker-compose up -d
    if [ $? -eq 0 ]; then
        TEXT='qBittorrent 安装成功' && INFO
    else
        TEXT='qBittorrent 安装失败，请尝试重新运行脚本' && ERROR
        exit 1
    fi
fi

if [[ ${docker_install_model} = 'cli' ]]; then
    docker run -dit \
        -v ${config_dir}/qbittorrent/config:/data \
        -v ${download_dir}:/downloads \
        -e PUID="${PUID}" \
        -e PGID="${PGID}" \
        -e TZ="${TZ}" \
        -e WEBUI_PORT="${qb_port}" \
        -e BT_PORT="${qb_port_torrent}" \
        -p ${qb_port}:${qb_port} \
        -p ${qb_port_torrent}:${qb_port_torrent}/tcp \
        -p ${qb_port_torrent}:${qb_port_torrent}/udp \
        --tmpfs /tmp \
        --restart always \
        --name ${container_name} \
        --hostname ${container_name} \
        ddsderek/videolab:qbittorrent-${BUILD_TIME}
    if [ $? -eq 0 ]; then
        TEXT='qBittorrent 安装成功' && INFO
    else
        TEXT='qBittorrent 安装失败，请尝试重新运行脚本' && ERROR
        exit 1
    fi
fi
}

qb_sk_install(){
clear
echo -e "${Blue}qBittorrent Skip Patch 安装${Font}\n"
get_container_name
qb_web_port
qb_port_torrent_i
sleep 2

clear
echo -e "${Blue}设置总览${Font}\n"
echo -e "${Green}qBittorrent Web 访问端口=${qb_port}${Font}"
echo -e "${Green}qBittorrent Torrent 端口=${qb_port_torrent}${Font}\n"
for i in `seq -w 5 -1 0`
do
    echo -en "${Green}即将开始安装${Font}${Blue} $i ${Font}\r"  
  sleep 1;
done

if [ ! -d ${config_dir}/qbittorrent_sk ]; then
    mkdir -p ${config_dir}/qbittorrent_sk
fi
if [ ! -d ${config_dir}/qbittorrent_sk/config ]; then
    mkdir -p ${config_dir}/qbittorrent_sk/config
fi
chown -R ${PUID}:${PGID} ${config_dir}/qbittorrent_sk
if [[ ${docker_install_model} = 'compose' ]]; then
    clear
    if [ ! -f ${config_dir}/qbittorrent_sk/docker-compose.yaml ]; then
        touch ${config_dir}/qbittorrent_sk/docker-compose.yaml
    fi
    cat > ${config_dir}/qbittorrent_sk/docker-compose.yaml << EOF
version: "2.0"
services:
  qbittorrent_sk:
    image: ddsderek/videolab:qbittorrent-${BUILD_TIME}
    container_name: ${container_name}
    restart: always
    tty: true
    network_mode: bridge
    hostname: ${container_name}
    volumes:
      - ${config_dir}/qbittorrent_sk/config:/data
      - ${download_dir}:/downloads
    tmpfs:
      - /tmp
    environment:
      - WEBUI_PORT=${qb_port}
      - BT_PORT=${qb_port_torrent}
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    ports:
      - ${qb_port}:${qb_port}
      - ${qb_port_torrent}:${qb_port_torrent}
      - ${qb_port_torrent}:${qb_port_torrent}/udp
EOF
    cd ${config_dir}/qbittorrent_sk
    docker-compose up -d
    if [ $? -eq 0 ]; then
        TEXT='qBittorrent 安装成功' && INFO
    else
        TEXT='qBittorrent 安装失败，请尝试重新运行脚本' && ERROR
        exit 1
    fi
fi

if [[ ${docker_install_model} = 'cli' ]]; then
    docker run -dit \
        -v ${config_dir}/qbittorrent/config:/data \
        -v ${download_dir}:/downloads \
        -e PUID="${PUID}" \
        -e PGID="${PGID}" \
        -e TZ="${TZ}" \
        -e WEBUI_PORT="${qb_port}" \
        -e BT_PORT="${qb_port_torrent}" \
        -p ${qb_port}:${qb_port} \
        -p ${qb_port_torrent}:${qb_port_torrent}/tcp \
        -p ${qb_port_torrent}:${qb_port_torrent}/udp \
        --tmpfs /tmp \
        --restart always \
        --name ${container_name} \
        --hostname ${container_name} \
        ddsderek/videolab:qbittorrent-${BUILD_TIME}
    if [ $? -eq 0 ]; then
        TEXT='qBittorrent 安装成功' && INFO
    else
        TEXT='qBittorrent 安装失败，请尝试重新运行脚本' && ERROR
        exit 1
    fi
fi
}

downloader_install(){
clear
choose_downloader
if [[ ${the_downloader_install} = 'tr' ]]; then
tr_install
elif [[ ${the_downloader_install} = 'qb' ]]; then
qb_install
elif [[ ${the_downloader_install} = 'aria2' ]]; then
for i in `seq -w 3 -1 0`
do
    echo -en "${Red}目前不支持Aria2 ,请选择其他下载器${Font}${Green} $i ${Font}\r"  
  sleep 1;
done
downloader_install
elif [[ ${the_downloader_install} = 'tr_sk' ]]; then
tr_sk_install
elif [[ ${the_downloader_install} = 'qb_sk' ]]; then
qb_sk_install
fi
}



choose_mediaserver(){
    echo -e "${Blue}媒体播放器${Font}\n"
    echo -e "——————————————————————————————————————————————————————————————————————————————————"
    echo -e "1、Plex"
    echo -e "2、Emby"
    echo -e "3、jellyfin"
    echo -e "4、跳过媒体播放器安装部分"
    echo -e "——————————————————————————————————————————————————————————————————————————————————"
    read -ep "请输入数字 [1-4]:" num
    case "$num" in
    1)
    the_mediaserver_install=plex
    ;;
    2)
    the_mediaserver_install=emby
    ;;
    3)
    the_mediaserver_install=jellyfin
    ;;
    4)
    the_mediaserver_install=false
    ;;
    *)
    clear
    TEXT='请输入正确数字 [1-4]' && ERROR
    choose_mediaserver
    ;;
    esac
}


plex_web_port(){
echo -e "${Green}请输入Plex Web 访问端口（默认 32400 ）${Font}"
read -ep "PORT:" plex_port
[[ -z "${plex_port}" ]] && plex_port="32400"
TEST_PORT=${plex_port}
port_if
if [[ ${TEST_PORT_IF=} = '1' ]]; then
    TEXT='端口被占用，请重新输入新端口' && ERROR
    plex_web_port
else
    TEXT='设置成功！' && INFO
fi
echo
}
plex_install(){
clear
echo -e "${Blue}Plex 安装${Font}\n"
get_container_name
plex_web_port
sleep 2

clear
echo -e "${Blue}设置总览${Font}\n"
echo -e "${Green}Plex Web 访问端口=${plex_port}${Font}"
for i in `seq -w 3 -1 0`
do
    echo -en "${Green}即将开始安装${Font}${Blue} $i ${Font}\r"  
  sleep 1;
done

if [ ! -d ${config_dir}/plex ]; then
    mkdir -p ${config_dir}/plex
fi
if [ ! -d ${config_dir}/plex/config ]; then
    mkdir -p ${config_dir}/plex/config
fi
if [ ! -d ${config_dir}/plex/transcode ]; then
    mkdir -p ${config_dir}/plex/transcode
fi
chown -R ${PUID}:${PGID} ${config_dir}/plex
if [[ ${docker_install_model} = 'compose' ]]; then
    clear
    if [ ! -f ${config_dir}/plex/docker-compose.yaml ]; then
        touch ${config_dir}/plex/docker-compose.yaml
    fi
    cat > ${config_dir}/plex/docker-compose.yaml << EOF
version: '2'
services:
  plex:
    container_name: ${container_name}
    image: plexinc/pms-docker
    restart: always
    ports:
      - ${plex_port}:32400/tcp
#      - 3005:3005/tcp
#      - 8324:8324/tcp
#      - 32469:32469/tcp
#      - 1900:1900/udp
#      - 32410:32410/udp
#      - 32412:32412/udp
#      - 32413:32413/udp
#      - 32414:32414/udp
    environment:
      - TZ=${TZ}
      - PLEX_UID=${PUID}
      - PLEX_GID=${PGID}
#      - PLEX_CLAIM=<claimToken>
#      - ADVERTISE_IP=http://<hostIPAddress>:32400/
    hostname: ${container_name}
    volumes:
      - ${config_dir}/plex/config:/config
      - ${config_dir}/plex/transcode:/transcode
      - ${media_dir}:/data
EOF
    cd ${config_dir}/plex
    docker-compose up -d
    if [ $? -eq 0 ]; then
        TEXT='Plex 安装成功' && INFO
    else
        TEXT='Plex 安装失败，请尝试重新运行脚本' && ERROR
        exit 1
    fi
fi

if [[ ${docker_install_model} = 'cli' ]]; then
    docker run \
        -d \
        --name ${container_name} \
        -p ${plex_port}:32400/tcp \
        -e TZ="${TZ}" \
        -h ${container_name} \
        -v ${config_dir}/plex/config:/config \
        -v ${config_dir}/plex/transcode:/transcode \
        -v ${media_dir}:/data \
        --restart always \
        plexinc/pms-docker
    if [ $? -eq 0 ]; then
        TEXT='Plex 安装成功' && INFO
    else
        TEXT='Plex 安装失败，请尝试重新运行脚本' && ERROR
        exit 1
    fi
fi
}

emby_web_port(){
echo -e "${Green}请输入Emby Web 访问端口（默认 8096 ）${Font}"
read -ep "PORT:" emby_port
[[ -z "${emby_port}" ]] && emby_port="8096"
TEST_PORT=${emby_port}
port_if
if [[ ${TEST_PORT_IF=} = '1' ]]; then
    TEXT='端口被占用，请重新输入新端口' && ERROR
    emby_web_port
else
    TEXT='设置成功！' && INFO
fi
echo
}
emby_install(){
clear
echo -e "${Blue}Emby 安装${Font}\n"
get_container_name
emby_web_port
sleep 2

clear
echo -e "${Blue}设置总览${Font}\n"
echo -e "${Green}Emby Web 访问端口=${emby_port}${Font}"
for i in `seq -w 3 -1 0`
do
    echo -en "${Green}即将开始安装${Font}${Blue} $i ${Font}\r"  
  sleep 1;
done

if [ ! -d ${config_dir}/emby ]; then
    mkdir -p ${config_dir}/emby
fi
if [ ! -d ${config_dir}/emby/config ]; then
    mkdir -p ${config_dir}/emby/config
fi
chown -R ${PUID}:${PGID} ${config_dir}/emby
if [[ ${docker_install_model} = 'compose' ]]; then
    clear
    if [ ! -f ${config_dir}/emby/docker-compose.yaml ]; then
        touch ${config_dir}/emby/docker-compose.yaml
    fi
    cat > ${config_dir}/emby/docker-compose.yaml << EOF
version: "2.3"
services:
  emby:
    image: emby/embyserver:latest
    container_name: ${container_name}
#    runtime: nvidia
    environment:
      - UID=${PUID}
      - GID=${PGID}
#      - GIDLIST=100
      - TZ=${TZ}
    volumes:
      - ${config_dir}/emby/config:/config
      - ${media_dir}:/data
    ports:
      - ${emby_port}:8096
#      - 8920:8920
#    devices:
#      - /dev/dri:/dev/dri
#      - /dev/vchiq:/dev/vchiq
    restart: always
EOF
    cd ${config_dir}/emby
    docker-compose up -d
    if [ $? -eq 0 ]; then
        TEXT='Emby 安装成功' && INFO
    else
        TEXT='Emby 安装失败，请尝试重新运行脚本' && ERROR
        exit 1
    fi
fi
if [[ ${docker_install_model} = 'cli' ]]; then
    docker run -d \
        --name ${container_name} \
        --volume ${config_dir}/emby/config:/config \
        --volume ${media_dir}:/data \
        --publish ${emby_port}:8096 \
        --env UID=${PUID} \
        --env GID=${PGID} \
        --env TZ=${TZ} \
        --restart always \
        emby/embyserver:latest
    if [ $? -eq 0 ]; then
        TEXT='Emby 安装成功' && INFO
    else
        TEXT='Emby 安装失败，请尝试重新运行脚本' && ERROR
        exit 1
    fi
fi
}

jellyfin_web_port(){
echo -e "${Green}请输入Jellyfin Web 访问端口（默认 8096 ）${Font}"
read -ep "PORT:" jellyfin_port
[[ -z "${jellyfin_port}" ]] && jellyfin_port="8096"
TEST_PORT=${jellyfin_port}
port_if
if [[ ${TEST_PORT_IF=} = '1' ]]; then
    TEXT='端口被占用，请重新输入新端口' && ERROR
    jellyfin_web_port
else
    TEXT='设置成功！' && INFO
fi
echo
}
jellyfin_install(){
clear
echo -e "${Blue}Jellyfin 安装${Font}\n"
get_container_name
jellyfin_web_port
sleep 2

clear
echo -e "${Blue}设置总览${Font}\n"
echo -e "${Green}jellyfin Web 访问端口=${jellyfin_port}${Font}"
for i in `seq -w 3 -1 0`
do
    echo -en "${Green}即将开始安装${Font}${Blue} $i ${Font}\r"  
  sleep 1;
done

if [ ! -d ${config_dir}/jellyfin ]; then
    mkdir -p ${config_dir}/jellyfin
fi
if [ ! -d ${config_dir}/jellyfin/config ]; then
    mkdir -p ${config_dir}/jellyfin/config
fi
if [ ! -d ${config_dir}/jellyfin/cache ]; then
    mkdir -p ${config_dir}/jellyfin/cache
fi
chown -R ${PUID}:${PGID} ${config_dir}/jellyfin
if [[ ${docker_install_model} = 'compose' ]]; then
    clear
    if [ ! -f ${config_dir}/jellyfin/docker-compose.yaml ]; then
        touch ${config_dir}/jellyfin/docker-compose.yaml
    fi
    cat > ${config_dir}/jellyfin/docker-compose.yaml << EOF
version: '3.5'
services:
  jellyfin:
    image: jellyfin/jellyfin
    container_name: ${container_name}
    user: ${PUID}:${PGID}
    ports:
      - ${jellyfin_port}:8096
    volumes:
      - ${config_dir}/jellyfin/config:/config
      - ${config_dir}/jellyfin/cache:/cache
      - ${media_dir}:/media
    restart: 'always'
#    environment:
#      - JELLYFIN_PublishedServerUrl=http://example.com
EOF
    cd ${config_dir}/jellyfin
    docker-compose up -d
    if [ $? -eq 0 ]; then
        TEXT='Jellyfin 安装成功' && INFO
    else
        TEXT='Jellyfin 安装失败，请尝试重新运行脚本' && ERROR
        exit 1
    fi
fi
if [[ ${docker_install_model} = 'cli' ]]; then
    docker run -d \
        --name ${container_name} \
        --user ${PUID}:${PGID} \
        --publish ${jellyfin_port}:8096 \
        --volume ${config_dir}/jellyfin/config:/config \
        --volume ${config_dir}/jellyfin/config:/cache \
        --mount type=bind,source=${media_dir},target=/media \
        --restart=always \
        jellyfin/jellyfin
    if [ $? -eq 0 ]; then
        TEXT='Jellyfin 安装成功' && INFO
    else
        TEXT='Jellyfin 安装失败，请尝试重新运行脚本' && ERROR
        exit 1
    fi
fi
}

mediaserver_install(){
clear
choose_mediaserver
if [[ ${the_mediaserver_install} = 'plex' ]]; then
plex_install
elif [[ ${the_mediaserver_install} = 'emby' ]]; then
emby_install
elif [[ ${the_mediaserver_install} = 'jellyfin' ]]; then
jellyfin_install
fi
}

direct_install(){
clear
fix_basic_settings
nastool_install
downloader_install
mediaserver_install
TEXT='安装完成，接下来请进入Web界面设置' && INFO
exit 0
}

manual_install(){
    echo -e "${Blue}手动安装${Font}\n"
    echo -e "——————————————————————————————————————————————————————————————————————————————————"
    echo -e "1、基础设置"
    echo -e "2、NAStool"
    echo -e "3、下载器"
    echo -e "4、媒体服务器"
    echo -e "5、返回上级目录"    
    echo -e "——————————————————————————————————————————————————————————————————————————————————"
    read -ep "请输入数字 [1-5]:" num
    case "$num" in
    1)
    fix_basic_settings
    manual_install
    ;;
    2)
    . /etc/videolab/settings.sh
    . ${config_dir}/nastools_all_in_one/basic_settings.sh
    nastool_install
    clear
    manual_install
    ;;
    3)
    . /etc/videolab/settings.sh
    . ${config_dir}/nastools_all_in_one/basic_settings.sh
    downloader_install
    clear
    manual_install
    ;;
    4)
    . /etc/videolab/settings.sh
    . ${config_dir}/nastools_all_in_one/basic_settings.sh
    mediaserver_install
    clear
    manual_install
    ;;
    5)
    clear
    main_return
    ;;
    *)
    clear
    TEXT='请输入正确数字 [1-5]' && ERROR
    manual_install
    ;;
    esac
}

main_return(){
    echo -e "${Blue}use os: ${OSNAME}${Font}"
    echo -e "——————————————————————————————————————————————————————————————————————————————————
 _   _    _    ____  _              _ 
| \ | |  / \  / ___|| |_ ___   ___ | |
|  \| | / _ \ \___ \| __/ _ \ / _ \| |
| |\  |/ ___ \ ___) | || (_) | (_) | |
|_| \_/_/   \_\____/ \__\___/ \___/|_|

Copyright (c) 2022 DDSRem <https://blog.ddsrem.com>

This is free software, licensed under the GNU General Public License.

——————————————————————————————————————————————————————————————————————————————————"
    echo -e "${Blue}NAStool All In One${Font}\n"
    echo -e "1、向导安装"
    echo -e "2、手动设置"
    echo -e "3、更新容器"
    echo -e "4、退出脚本"
    echo -e "——————————————————————————————————————————————————————————————————————————————————"
    read -ep "请输入数字 [1-4]:" num
    case "$num" in
        1)
        direct_install
        ;;
        2)
        clear
        manual_install
        ;;
        3)
        clear
        update_containers
        ;;
        4)
        clear
        exit 0
        ;;
        *)
        clear
        TEXT='请输入正确数字 [1-4]' && ERROR
        main_return
        ;;
        esac
}

# 主菜单
main(){
    # 检测是否为 root 用户
    root_need
    # 清理命令行
    clear
    # 安装软件包
    package_installation
    # 清理命令行
    clear
    # 旧配置兼容
    if [ -d /etc/nastools_all_in_one ]; then
        mv /etc/nastools_all_in_one /etc/videolab
    fi
    main_return
}

main