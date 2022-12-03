#!/usr/bin/env bash

Green="\033[32m"
Font="\033[0m"
Red="\033[31m" 
Blue="\033[34m"

BUILD_TIME=2022-12-03

#root权限
root_need(){
    if [[ $EUID -ne 0 ]]; then
        echo -e "${Red}错误：此脚本必须以 root 身份运行！${Font}"
        exit 1
    fi
}

# 软件包安装
package_installation(){
    _os=`uname`
    echo -e "${Blue}use system: ${_os}${Font}"
    if [ ${_os} == "Darwin" ]; then
        OSNAME='macos'
        echo -e "${Red}错误：此系统无法使用此脚本${Font}"
        exit 1
    elif grep -Eq "openSUSE" /etc/*-release; then
        OSNAME='opensuse'
        zypper refresh
    elif grep -Eq "FreeBSD" /etc/*-release; then
        OSNAME='freebsd'
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
        echo -e "${Red}错误：此系统无法使用此脚本${Font}"
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

get_PUID(){
echo -e "${Green}请输入媒体文件所有者的用户ID（默认 0 ）${Font}"
read -p "PUID:" NEW_PUID
[[ -z "${NEW_PUID}" ]] && NEW_PUID="0"
}
get_PGID(){
echo -e "${Green}请输入媒体文件所有者的用户组ID（默认 0 ）${Font}"
read -p "PGID:" NEW_PGID
[[ -z "${NEW_PGID}" ]] && NEW_PGID="0"
}
get_id(){
echo -e "${Blue}容器用户和用户组ID设置"
echo -e "前往 https://github.com/jxxghp/nas-tools/tree/master/docker#%E5%85%B3%E4%BA%8Epuidpgid%E7%9A%84%E8%AF%B4%E6%98%8E 查看uid获取方法\n"
get_PUID
echo
get_PGID
}
get_umask(){
echo -e "${Blue}容器Umask设置\n"
echo -e "${Green}请输入Umask（默认 000 ）${Font}"
read -p "Umask:" NEW_UMASK
[[ -z "${NEW_UMASK}" ]] && NEW_UMASK="000"
}
get_tz(){
echo -e "${Blue}容器时区设置\n"
echo -e "${Green}请输入时区（默认 Asia/Shanghai ）${Font}"
read -p "TZ:" NEW_TZ
[[ -z "${NEW_TZ}" ]] && NEW_TZ="Asia/Shanghai"
}
get_config_dir(){
echo -e "${Blue}文件路径设置\n"
echo -e "${Green}请输入配置文件存放路径（默认 /root/data ）${Font}"
read -p "DIR:" NEW_config_dir
[[ -z "${NEW_config_dir}" ]] && NEW_config_dir="/root/data"
echo 
}
get_download_dir(){
echo -e "${Green}请输入下载目录路径（默认 /media/downloads ）${Font}"
echo -e "${Red}注意，下载目录路径应在媒体目录文件夹下\n比如说媒体路径为/media，那么下载路径应填/media/downloads${Font}"
read -p "DIR:" NEW_download_dir
[[ -z "${NEW_download_dir}" ]] && NEW_download_dir="/media/downloads"
echo 
}
get_media_dir(){
echo -e "${Green}请输入媒体路径（默认 /media ）${Font}"
echo -e "${Red}注意，下载目录路径应在媒体目录文件夹下\n比如说媒体路径为/media，那么下载路径应填/media/downloads${Font}"
read -p "DIR:" NEW_media_dir
[[ -z "${NEW_media_dir}" ]] && NEW_media_dir="/media"
echo 
}
choose_docker_install_model(){
    clear
    echo -e "${Blue}容器安装模式选择${Font}\n"
    echo -e "——————————————————————————————————————————————————————————————————————————————————"
    echo -e "1、docker-cli安装模式"
    echo -e "2、docker-compose安装模式"
    echo -e "——————————————————————————————————————————————————————————————————————————————————"
    read -p "请输入数字 [1-2]:" num
    case "$num" in
    1)
    NEW_docker_install_model=cli
    ;;
    2)
    NEW_docker_install_model=compose
    ;;
    *)
    clear
    echo -e "${Red}请输入正确数字 [1-2]${Font}"
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
if [ ! -d /etc/nastools_all_in_one ]; then
    mkdir -p /etc/nastools_all_in_one
fi
if [ ! -f ${NEW_config_dir}/nastools_all_in_one ]; then
    touch ${NEW_config_dir}/nastools_all_in_one/basic_settings.sh
fi
if [ ! -f /etc/nastools_all_in_one/settings.sh ]; then
    touch /etc/nastools_all_in_one/settings.sh
fi
cat > ${NEW_config_dir}/nastools_all_in_one/basic_settings.sh << EOF
#!/usr/bin/env bash

PUID=${NEW_PUID}
PGID=${NEW_PGID}
Umask=${NEW_UMASK}

TZ=${NEW_TZ}

download_dir=${NEW_download_dir}
media_dir=${NEW_media_dir}

docker_install_model=${NEW_docker_install_model}

EOF
cat > /etc/nastools_all_in_one/settings.sh << EOF
#!/usr/bin/env bash

config_dir=${NEW_config_dir}

EOF

#. /etc/nastools_all_in_one/settings.sh
#. ${config_dir}/nastools_all_in_one/basic_settings.sh

if [ $? -eq 0 ]; then
echo -e "${Green}保存成功${Font}"
fi
}
show_basic_settings(){
    echo -e "${Blue}基础设置总览${Font}\n"
    echo -e "${Green}PUID=${NEW_PUID}${Font}"
    echo -e "${Green}PGID=${NEW_PGID}${Font}"
    echo -e "${Green}Umask=${NEW_UMASK}${Font}"
    echo -e "${Green}TZ=${NEW_TZ}${Font}"
    echo -e "${Green}配置文件存放路径 ${NEW_config_dir}${Font}"
    echo -e "${Green}下载目录路径 ${NEW_download_dir}${Font}"
    echo -e "${Green}媒体最终存放路径 ${NEW_media_dir}${Font}"
    echo -e "${Green}容器安装模式docker-${NEW_docker_install_model}${Font}\n"
    echo -e "——————————————————————————————————————————————————————————————————————————————————"
    echo -e "1、修改PUID"
    echo -e "2、修改PGID"
    echo -e "3、修改Umask"
    echo -e "4、修改时区"
    echo -e "5、修改配置文件存放路径"
    echo -e "6、修改媒体存放路径"
    echo -e "7、修改下载目录路径"
    echo -e "8、修改容器安装模式选择"
    echo -e "9、保存配置"
    echo -e "——————————————————————————————————————————————————————————————————————————————————"
    read -p "请输入数字 [1-9]:" num
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
        get_tz
        clear
        show_basic_settings
        ;;
        5)
        get_config_dir
        clear
        show_basic_settings
        ;;
        6)
        get_media_dir
        clear
        show_basic_settings
        ;;
        7)
        get_download_dir
        clear
        show_basic_settings
        ;;
        8)
        choose_docker_install_model
        clear
        show_basic_settings
        ;;
        9)
        save_basic_settings
        ;;
        *)
        clear
        echo -e "${Red}请输入正确数字 [1-8]${Font}"
        show_basic_settings
        ;;
        esac
}

fix_basic_settings(){
clear
if [ ! -f /etc/nastools_all_in_one/settings.sh ]; then
    get_id
    clear
    get_umask
    clear
    get_tz
    clear
    get_config_dir
    get_media_dir
    get_download_dir
    choose_docker_install_model
    clear
    show_basic_settings
else
    . /etc/nastools_all_in_one/settings.sh
    . ${config_dir}/nastools_all_in_one/basic_settings.sh
    Old_PUID=${PUID}
    Old_PGID=${PGID}
    Old_Umask=${Umask}
    Old_TZ=${TZ}
    Old_download_dir=${download_dir}
    Old_media_dir=${media_dir}
    Old_config_dir=${config_dir}
    Old_docker_install_model=${docker_install_model}

    NEW_PUID=${Old_PUID}
    NEW_PGID=${Old_PGID}
    NEW_UMASK=${Old_Umask}
    NEW_TZ=${Old_TZ}
    NEW_download_dir=${Old_download_dir}
    NEW_media_dir=${Old_media_dir}
    NEW_config_dir=${Old_config_dir}
    NEW_docker_install_model=${Old_docker_install_model}
    show_basic_settings
fi
}

get_nastool_port(){
echo -e "${Green}请输入NAStool Web 访问端口（默认 3000 ）${Font}"
read -p "PORT:" NAStool_port
[[ -z "${NAStool_port}" ]] && NAStool_port="3000"
TEST_PORT=${NAStool_port}
port_if
if [[ ${TEST_PORT_IF=} = '1' ]]; then
    echo -e "${Red}端口被占用，请重新输入新端口${Font}"
    get_nastool_port
else
    echo -e "${Green}设置成功！${Font}"
fi
}
get_nastool_update(){
echo -e "${Green}是否启用重启更新 [Y/n]（默认 n ）${Font}"
read -p "PORT:" NAStool_update
[[ -z "${NAStool_update}" ]] && NAStool_update="n"
if [[ ${NAStool_update} == [Yy] ]]; then
NAStool_update_eld=true
fi
if [[ ${NAStool_update} == [Nn] ]]; then
NAStool_update_eld=false
fi
}
nastool_install(){
clear
echo -e "${Blue}NAStool 安装${Font}\n"
get_nastool_port
get_nastool_update
. /etc/nastools_all_in_one/settings.sh
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
        mkdir -p ${config_dir}/nas-tools/docker-compose.yaml
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
    hostname: nas-tools
    container_name: nas-tools
EOF
    cd ${config_dir}/nas-tools
    docker compose up -d
fi
if [[ ${docker_install_model} = 'cli' ]]; then
    clear
    docker run -d \
        --name nas-tools \
        --hostname nas-tools \
        -p ${NAStool_port}:3000\
        -v ${config_dir}/nas-tools/config:/config \
        -v ${media_dir}:/media \
        -e PUID=${PUID} \
        -e PGID=${PGID} \
        -e UMASK=${Umask} \
        -e NASTOOL_AUTO_UPDATE=${NAStool_update_eld} \
        --restart always \
        jxxghp/nas-tools:latest
fi
if [ $? -eq 0 ]; then
    echo -e "${Green}NAStools 安装成功${Font}"
else
    echo -e "${Red}NAStools 安装失败，请尝试重新运行脚本${Font}"
    exit 1
fi
}


choose_downloader(){
    clear
    echo -e "${Blue}选择安装下载器${Font}\n"
    echo -e "——————————————————————————————————————————————————————————————————————————————————"
    echo -e "1、Transmission"
    echo -e "2、qBittorrent"
    echo -e "3、Aria2-Pro"
    echo -e "4、Transmission快验版"
    echo -e "5、qBittorrent快验版"
    echo -e "6、跳过下载器安装部分"
    echo -e "——————————————————————————————————————————————————————————————————————————————————"
    read -p "请输入数字 [1-6]:" num
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
    echo -e "${Red}请输入正确数字 [1-6]${Font}"
    choose_downloader
    ;;
    esac
}

tr_web_port(){
echo -e "${Green}请输入Transmission Web 访问端口（默认 9091 ）${Font}"
read -p "PORT:" tr_port
[[ -z "${tr_port}" ]] && tr_port="9091"
TEST_PORT=${tr_port}
port_if
if [[ ${TEST_PORT_IF=} = '1' ]]; then
    echo -e "${Red}端口被占用，请重新输入新端口${Font}"
    tr_web_port
else
    echo -e "${Green}设置成功！${Font}"
fi
echo
}
tr_port_torrent_i(){
echo -e "${Green}请输入Transmission Torrent 端口（默认 51413 ）${Font}"
read -p "PORT:" tr_port_torrent 
[[ -z "${tr_port_torrent}" ]] && tr_port_torrent="51413"
TEST_PORT=${tr_port_torrent}
port_if
if [[ ${TEST_PORT_IF=} = '1' ]]; then
    echo -e "${Red}端口被占用，请重新输入新端口${Font}"
    tr_port_torrent_i
else
    echo -e "${Green}设置成功！${Font}"
fi
echo
}
tr_install(){
clear
echo -e "${Blue}Transmission 安装${Font}\n"
tr_web_port
tr_port_torrent_i
echo -e "${Green}请输入Transmission Web 用户名（默认 username ）${Font}"
read -p "USERNAME:" tr_username
[[ -z "${tr_username}" ]] && tr_username="username"
echo -e "${Green}设置成功！${Font}"
echo
echo -e "${Green}请输入Transmission Web 密码（默认 password ）${Font}"
read -p "PASSWORD:" tr_password
[[ -z "${tr_password}" ]] && tr_password="password"
echo -e "${Green}设置成功！${Font}"

if [ ! -d ${config_dir}/transmission ]; then
    mkdir -p ${config_dir}/transmission
fi
if [ ! -d ${config_dir}/transmission/config ]; then
    mkdir -p ${config_dir}/transmission/config
fi

if [[ ${docker_install_model} = 'compose' ]]; then
    clear
    if [ ! -f ${config_dir}/transmission/docker-compose.yaml ]; then
        mkdir -p ${config_dir}/transmission/docker-compose.yaml
    fi
    cat > ${config_dir}/transmission/docker-compose.yaml << EOF
version: "2.1"
services:
  transmission:
    image: ddsderek/nas-tools-all-in-one:transmission-${BUILD_TIME}
    container_name: transmission
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
    docker compose up -d
fi

if [[ ${docker_install_model} = 'cli' ]]; then
    docker run -d \
    --name=transmission \
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
    ddsderek/nas-tools-all-in-one:transmission-${BUILD_TIME}
fi

if [ $? -eq 0 ]; then
    echo -e "${Green}Transmission 安装成功${Font}"
else
    echo -e "${Red}Transmission 安装失败，请尝试重新运行脚本${Font}"
    exit 1
fi
}

tr_sk_install(){
clear
echo -e "${Blue}Transmission Skip Patch 安装${Font}\n"
tr_web_port
tr_port_torrent_i
echo -e "${Green}请输入Transmission Web 用户名（默认 username ）${Font}"
read -p "USERNAME:" tr_username
[[ -z "${tr_username}" ]] && tr_username="username"
echo -e "${Green}设置成功！${Font}"
echo
echo -e "${Green}请输入Transmission Web 密码（默认 password ）${Font}"
read -p "PASSWORD:" tr_password
[[ -z "${tr_password}" ]] && tr_password="password"
echo -e "${Green}设置成功！${Font}"

if [ ! -d ${config_dir}/transmission_sk ]; then
    mkdir -p ${config_dir}/transmission_sk
fi
if [ ! -d ${config_dir}/transmission_sk/config ]; then
    mkdir -p ${config_dir}/transmission_sk/config
fi

if [[ ${docker_install_model} = 'compose' ]]; then
    clear
    if [ ! -f ${config_dir}/transmission_sk/docker-compose.yaml ]; then
        mkdir -p ${config_dir}/transmission_sk/docker-compose.yaml
    fi
    cat > ${config_dir}/transmission_sk/docker-compose.yaml << EOF
version: "2.1"
services:
  transmission_sk:
    image: ddsderek/nas-tools-all-in-one:transmission_skip_patch-${BUILD_TIME}
    container_name: transmission_sk
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
    docker compose up -d
fi

if [[ ${docker_install_model} = 'cli' ]]; then
    docker run -d \
    --name=transmission_sk \
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
    ddsderek/nas-tools-all-in-one:transmission_skip_patch-${BUILD_TIME}
fi

if [ $? -eq 0 ]; then
    echo -e "${Green}Transmission Skip Patch 安装成功${Font}"
else
    echo -e "${Red}Transmission Skip Patch 安装失败，请尝试重新运行脚本${Font}"
    exit 1
fi
}

qb_web_port(){
echo -e "${Green}请输入qBittorrent Web 访问端口（默认 8080 ）${Font}"
read -p "PORT:" qb_port
[[ -z "${qb_port}" ]] && qb_port="8080"
TEST_PORT=${qb_port}
port_if
if [[ ${TEST_PORT_IF=} = '1' ]]; then
    echo -e "${Red}端口被占用，请重新输入新端口${Font}"
    qb_web_port
else
    echo -e "${Green}设置成功！${Font}"
fi
echo
}
qb_port_torrent_i(){
echo -e "${Green}请输入qBittorrent Torrent 端口（默认 34567 ）${Font}"
read -p "PORT:" qb_port_torrent 
[[ -z "${qb_port_torrent}" ]] && qb_port_torrent="34567"
TEST_PORT=${qb_port_torrent}
port_if
if [[ ${TEST_PORT_IF=} = '1' ]]; then
    echo -e "${Red}端口被占用，请重新输入新端口${Font}"
    qb_port_torrent_i
else
    echo -e "${Green}设置成功！${Font}"
fi
echo
}
qb_install(){
clear
echo -e "${Blue}qBittorrent 安装${Font}\n"
qb_web_port
qb_port_torrent_i

if [ ! -d ${config_dir}/qbittorrent ]; then
    mkdir -p ${config_dir}/qbittorrent
fi
if [ ! -d ${config_dir}/qbittorrent/config ]; then
    mkdir -p ${config_dir}/qbittorrent/config
fi

if [[ ${docker_install_model} = 'compose' ]]; then
    clear
    if [ ! -f ${config_dir}/qbittorrent/docker-compose.yaml ]; then
        mkdir -p ${config_dir}/qbittorrent/docker-compose.yaml
    fi
    cat > ${config_dir}/qbittorrent/docker-compose.yaml << EOF
version: "2.0"
services:
  qbittorrent:
    image: ddsderek/nas-tools-all-in-one:qbittorrent-${BUILD_TIME}
    container_name: qbittorrent
    restart: always
    tty: true
    network_mode: bridge
    hostname: qbitorrent
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
    docker compose up -d
fi

if [[ ${docker_install_model} = 'cli' ]]; then
    docker run -dit \
        -v $PWD/qbittorrent:/data \
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
        --name qbittorrent \
        --hostname qbittorrent \
        ddsderek/nas-tools-all-in-one:qbittorrent-${BUILD_TIME}
fi

if [ $? -eq 0 ]; then
    echo -e "${Green}qBittorrent 安装成功${Font}"
else
    echo -e "${Red}qBittorrent 安装失败，请尝试重新运行脚本${Font}"
    exit 1
fi
}

qb_sk_install(){
clear
echo -e "${Blue}qBittorrent Skip Patch 安装${Font}\n"
qb_web_port
qb_port_torrent_i

if [ ! -d ${config_dir}/qbittorrent_sk ]; then
    mkdir -p ${config_dir}/qbittorrent_sk
fi
if [ ! -d ${config_dir}/qbittorrent_sk/config ]; then
    mkdir -p ${config_dir}/qbittorrent_sk/config
fi

if [[ ${docker_install_model} = 'compose' ]]; then
    clear
    if [ ! -f ${config_dir}/qbittorrent_sk/docker-compose.yaml ]; then
        mkdir -p ${config_dir}/qbittorrent_sk/docker-compose.yaml
    fi
    cat > ${config_dir}/qbittorrent_sk/docker-compose.yaml << EOF
version: "2.0"
services:
  qbittorrent_sk:
    image: ddsderek/nas-tools-all-in-one:qbittorrent-${BUILD_TIME}
    container_name: qbittorrent_sk
    restart: always
    tty: true
    network_mode: bridge
    hostname: qbittorrent_sk
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
    docker compose up -d
fi

if [[ ${docker_install_model} = 'cli' ]]; then
    docker run -dit \
        -v ${config_dir}/qbittorrent_sk/config:/data \
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
        --name qbittorrent_sk \
        --hostname qbittorrent_sk \
        ddsderek/nas-tools-all-in-one:qbittorrent-${BUILD_TIME}
fi

if [ $? -eq 0 ]; then
    echo -e "${Green}qBittorrent Skip Patch 安装成功${Font}"
else
    echo -e "${Red}qBittorrent Skip Patch 安装失败，请尝试重新运行脚本${Font}"
    exit 1
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
echo
elif [[ ${the_downloader_install} = 'tr_sk' ]]; then
tr_sk_install
elif [[ ${the_downloader_install} = 'qb_sk' ]]; then
qb_sk_install
fi
}








direct_install(){
clear
fix_basic_settings
#nastool_install
downloader_install
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
    # 输出主菜单
    echo -e "${Blue}NAStool All In One${Font}\n"
    echo -e "1、向导安装"
    echo -e "2、手动安装"
    echo -e "3、更新"
    echo -e "4、修改基础配置"
    echo -e "5、退出脚本"
    echo -e "——————————————————————————————————————————————————————————————————————————————————"
    read -p "请输入数字 [1-5]:" num
    case "$num" in
        1)
        direct_install
        ;;
        2)
        ;;
        3)
        ;;
        4)
        fix_basic_settings
        bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/DDS-Derek/nas-tools-all-in-one/master/install.sh')
        ;;
        5)
        exit 0
        ;;
        *)
        clear
        echo -e "${Red}请输入正确数字 [1-5]${Font}"
        main
        ;;
        esac
}

main
