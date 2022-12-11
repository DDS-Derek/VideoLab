#!/usr/bin/env bash

# 脚本在Ubuntu上可以正常使用，其他Linux系统未经过测试，理论上全部Linux都可用

. /etc/nastools_all_in_one/settings.sh
. ${config_dir}/nastools_all_in_one/basic_settings.sh
Media_DIR=${media_dir}

Green="\033[32m"
Font="\033[0m"
Red="\033[31m" 
Blue="\033[34m"

SAVEIFS=$IFS

changed=
deleted=

# 判断哪些文件需要重设权限
check_file(){
if [ ! -f ${PWD}/lock.sca.new ]; then
    touch ${PWD}/lock.sca.new
fi
# 保存旧文件列表
if [ -f ${PWD}/lock.sca.old ]; then
    rm -rf ${PWD}/lock.sca.old
    cp ${PWD}/lock.sca.new ${PWD}/lock.sca.old
else
    cp ${PWD}/lock.sca.new ${PWD}/lock.sca.old
fi
# 生成新列表
#find ${Media_DIR} -type f | xargs -d "\n" sha256sum > ${PWD}/lock.sca.new
find ${Media_DIR} -type f > ${PWD}/lock.sca.new
# 进行比对
diff ${PWD}/lock.sca.new ${PWD}/lock.sca.old > ${PWD}/lock.sca
#echo -e "$(grep '<' ${PWD}/lock.sca |awk '{$1=$2="";print}')\n" > lock.scb
# 输出修改结果
echo -e "$(grep '<' ${PWD}/lock.sca |awk '{$1=" ";print}')" > lock.scb
sed -i 's/  //g' lock.scb
#sed -i ':a;N;s/\n/" /g;ta' lock.scb
# 统一
file=$(cat lock.scb)
}

# 全部重设权限
check(){
if [ ! -f ${PWD}/lock.sc ]; then
    touch ${PWD}/lock.sc
fi
# 获取旧文件列表hash
hash_old=$(cat ${PWD}/lock.sc)
find ${Media_DIR} -type f | sha256sum > ${PWD}/lock.sc
# 获取新文件列表hash
hash_new=$(cat ${PWD}/lock.sc)
# 对比
if [ "$hash_old" != "$hash_new" ]; then
    # hash不同
    echo -e "${Blue}检测到新文件，设置权限中...${Font}"
    # 获取改变或者新加入的文件列表
    #check_file
    # 设置文件权限
    #chmod ${CFVR} ${file}
    chmod ${CFVR} ${Media_DIR}
    if [ $? -eq 0 ]; then
        echo -e "${Green}chmod 成功${Font}"
    else
        echo -e "${Red}chomd 失败${Font}"
        exit 1
    fi
    # 设置文件用户和用户组
    #chown ${PUID}:${PGID} ${file}
    chown ${PUID}:${PGID} ${Media_DIR}
    if [ $? -eq 0 ]; then
        echo -e "${Green}chown 成功${Font}"
    else
        echo -e "${Red}chown 失败${Font}"
        exit 1
    fi
else
    # hash相同
    echo -e "${Blue}无需设置${Font}"
fi
}

# 只给需要重设权限的文件重设权限
check1(){
if [ ! -f ${PWD}/lock.sc ]; then
    touch ${PWD}/lock.sc
fi
# 获取旧文件列表hash
hash_old=$(cat ${PWD}/lock.sc)
find ${Media_DIR} -type f | sha256sum > ${PWD}/lock.sc
# 获取新文件列表hash
hash_new=$(cat ${PWD}/lock.sc)
# 对比
if [ "$hash_old" != "$hash_new" ]; then
    # hash不同
    echo -e "${Blue}检测到新文件，设置权限中...${Font}"
    # 获取需要重设权限的文件列表
    check_file
    # 设置文件权限
    IFS=$(echo -en "\n\b")
    chmod ${CFVR} ${file}
    #chmod ${CFVR} ${Media_DIR}
    if [ $? -eq 0 ]; then
        echo -e "${Green}chmod 成功${Font}"
    else
        echo -e "${Red}chmod 失败${Font}"
        exit 1
    fi
    # 设置文件用户和用户组
    chown ${PUID}:${PGID} ${file}
    #chown ${PUID}:${PGID} ${Media_DIR}
    if [ $? -eq 0 ]; then
        echo -e "${Green}chown 成功${Font}"
    else
        echo -e "${Red}chown 失败${Font}"
        exit 1
    fi
    IFS=$SAVEIFS
else
    # hash相同
    echo -e "${Blue}无需设置${Font}"
fi
}

check1
