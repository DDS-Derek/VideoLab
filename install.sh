#!/usr/bin/env bash

Green="\033[32m"
Font="\033[0m"
Red="\033[31m" 
Blue="\033[34m"

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
        yum install -y wget zip unzip curl
    elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
        OSNAME='fedora'
        yum install -y wget zip unzip curl
    elif grep -Eqi "Rocky" /etc/issue || grep -Eq "Rocky" /etc/*-release; then
        OSNAME='rocky'
        yum install -y wget zip unzip curl
    elif grep -Eqi "AlmaLinux" /etc/issue || grep -Eq "AlmaLinux" /etc/*-release; then
        OSNAME='alma'
        yum install -y wget zip unzip curl
    elif grep -Eqi "Amazon Linux" /etc/issue || grep -Eq "Amazon Linux" /etc/*-release; then
        OSNAME='amazon'
        yum install -y wget zip unzip curl
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        OSNAME='debian'
        apt update -y
        apt install -y devscripts
        apt install -y wget zip unzip curl
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        OSNAME='ubuntu'
        apt install -y wget zip unzip curl
    elif grep -Eqi "Alpine" /etc/issue || grep -Eq "Alpine" /etc/*-release; then
        OSNAME='alpine'
        apk add wget zip unzip curl
    else
        OSNAME='unknow'
        echo -e "${Red}错误：此系统无法使用此脚本${Font}"
        exit 1
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
        jxxghp/nas-tools:latest
fi
}

#downloader_install(){

#}








direct_install(){
clear
fix_basic_settings
nastool_install
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
