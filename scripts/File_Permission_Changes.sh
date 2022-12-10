#!/usr/bin/env bash

Media_DIR=${MEDIA_DIR:=/home/video2}
CFVR=${CFVR:=755}
PUID=${PUID:=1000}
PGID=${PGID:=1000}

Green="\033[32m"
Font="\033[0m"
Red="\033[31m" 
Blue="\033[34m"

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
find ${Media_DIR} -type f|xargs md5sum > ${PWD}/lock.sca.new
# 将文件名作为遍历对象进行一一比对
for i in `awk '{print $2}' ${PWD}/lock.sca.new`
do
    # 以new为标准，当old不存在遍历对象中的文件时直接输出不存在的结果
    if grep -qw "$i" ${PWD}/lock.sca.old; then
        md5_new=`grep -w "$i" ${PWD}/lock.sca.new|awk '{print $1}'`
        md5_old=`grep -w "$i" ${PWD}/lock.sca.old|awk '{print $1}'`
        # 当文件存在时，如果md5值不一致则输出文件改变的结果
        if [ $md5_new != $md5_old ]; then
            changed="${changed} $i"
        fi
    else
        deleted="${deleted} $i"
    fi
done
# 统一文件
file="${changed} ${deleted}"
}

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
    # 获取改变或者新加入的文件列表
    check_file
    # 设置文件权限
    chmod ${CFVR} ${file}
    #chmod ${CFVR} ${Media_DIR}
    if [ $? -eq 0 ]; then
        echo -e "${Green}chmod 成功${Font}"
    else
        echo -e "${Red}chomd 失败${Font}"
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
else
    # hash相同
    echo -e "${Blue}无需设置${Font}"
fi
}

check