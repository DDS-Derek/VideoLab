#!/usr/bin/env bash

#
#
# 脚本在Ubuntu上可以正常使用，其他Linux系统未经过测试，理论上全部Linux都可用
#
# Thanks：https://blog.csdn.net/qq_45698148/article/details/120064768
#         https://blog.csdn.net/jks212454/article/details/124700284
# Use：curl -o File_Permission_Changes.sh https://ghproxy.com/https://raw.githubusercontent.com/DDS-Derek/nas-tools-all-in-one/master/scripts/File_Permission_Changes.sh
#      bash File_Permission_Changes.sh
#
#

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

# 判断哪些文件需要重设权限，通过文件名称判断，如果是修改文件则无法判断
check_file(){
if [ ! -f ${PWD}/lock.sc.new ]; then
    touch ${PWD}/lock.sc.new
fi
# 保存旧文件列表
if [ -f ${PWD}/lock.sc.old ]; then
    # 备份
    if [ -f ${PWD}/lock.sc.old.backup ]; then
        rm -rf ${PWD}/lock.sc.old.backup
    fi
    cp ${PWD}/lock.sc.old ${PWD}/lock.sc.old.backup
    rm -rf ${PWD}/lock.sc.old
    cp ${PWD}/lock.sc.new ${PWD}/lock.sc.old
    rm -rf ${PWD}/lock.sc.new
    touch ${PWD}/lock.sc.new
else
    # 第一次使用才会出现这种情况
    cp ${PWD}/lock.sc.new ${PWD}/lock.sc.old
    rm -rf ${PWD}/lock.sc.new
    touch ${PWD}/lock.sc.new
fi
# 生成新列表
find ${Media_DIR} -type f > ${PWD}/lock.sc.new
if [ $? -eq 0 ]; then
    echo -e "${Green}文件遍历成功${Font}"
else
    echo -e "${Red}文件遍历失败${Font}"
    exit 1
fi
# 进行比对
diff ${PWD}/lock.sc.new ${PWD}/lock.sc.old > ${PWD}/lock.sc.end
# 输出修改结果
echo -e "$(grep '<' ${PWD}/lock.sc.end |awk '{$1=" ";print}')" > lock.sc.end
sed -i 's/  //g' lock.sc.end
}

# 判断哪些文件需要重设权限，通过文件名称和md5值判断，如果是修改文件可以正常判断，但是需要的时间更长
check_file_md5sum(){
if [ ! -f ${PWD}/lock.sc.new ]; then
    touch ${PWD}/lock.sc.new
fi
# 保存旧文件列表
if [ -f ${PWD}/lock.sc.old ]; then
    # 备份
    if [ -f ${PWD}/lock.sc.old.backup ]; then
        rm -rf ${PWD}/lock.sc.old.backup
    fi
    cp ${PWD}/lock.sc.old ${PWD}/lock.sc.old.backup
    rm -rf ${PWD}/lock.sc.old
    cp ${PWD}/lock.sc.new ${PWD}/lock.sc.old
    rm -rf ${PWD}/lock.sc.new
    touch ${PWD}/lock.sc.new
else
    # 第一次使用才会出现这种情况
    cp ${PWD}/lock.sc.new ${PWD}/lock.sc.old
    rm -rf ${PWD}/lock.sc.new
    touch ${PWD}/lock.sc.new
fi
# 生成新列表
find ${Media_DIR} -type f | xargs -d "\n" md5sum > ${PWD}/lock.sc.new
if [ $? -eq 0 ]; then
    echo -e "${Green}文件遍历成功${Font}"
else
    echo -e "${Red}文件遍历失败${Font}"
    exit 1
fi
# 进行比对
diff ${PWD}/lock.sc.new ${PWD}/lock.sc.old > ${PWD}/lock.sc.cp
# 输出修改结果
grep '<' ${PWD}/lock.sc.cp |awk '{$1=$2="";print}' > lock.sc.end
sed -i 's/  //g' lock.sc.end
}


# 判断哪些文件夹需要重设权限，通过文件夹名称和修改时间判断，如果是修改文件夹可以正常判断
check_dir_time(){
if [ ! -f ${PWD}/lock.sd.new ]; then
    touch ${PWD}/lock.sd.new
fi
# 保存旧文件列表
if [ -f ${PWD}/lock.sd.old ]; then
    # 备份
    if [ -f ${PWD}/lock.sd.old.backup ]; then
        rm -rf ${PWD}/lock.sd.old.backup
    fi
    cp ${PWD}/lock.sd.old ${PWD}/lock.sd.old.backup
    rm -rf ${PWD}/lock.sd.old
    cp ${PWD}/lock.sd.new ${PWD}/lock.sd.old
    rm -rf ${PWD}/lock.sd.new
    touch ${PWD}/lock.sd.new
else
    # 第一次使用才会出现这种情况
    cp ${PWD}/lock.sd.new ${PWD}/lock.sd.old
    rm -rf ${PWD}/lock.sd.new
    touch ${PWD}/lock.sd.new
fi
# 生成新列表
find ${Media_DIR} -type d -printf "%TY-%Tm-%Td_%TH:%TM:%TS_%Tz  %p\n" > ${PWD}/lock.sd.new
if [ $? -eq 0 ]; then
    echo -e "${Green}文件遍历成功${Font}"
else
    echo -e "${Red}文件遍历失败${Font}"
    exit 1
fi
# 进行比对
diff ${PWD}/lock.sd.new ${PWD}/lock.sd.old > ${PWD}/lock.sd.cp
# 输出修改结果
grep '<' ${PWD}/lock.sd.cp |awk '{$1=$2="";print}' > lock.sd.end
sed -i 's/  //g' lock.sd.end
}

# 判断哪些文件需要重设权限，通过文件名称和修改时间判断，如果是修改文件可以正常判断
check_file_time(){
if [ ! -f ${PWD}/lock.sc.new ]; then
    touch ${PWD}/lock.sc.new
fi
# 保存旧文件列表
if [ -f ${PWD}/lock.sc.old ]; then
    # 备份
    if [ -f ${PWD}/lock.sc.old.backup ]; then
        rm -rf ${PWD}/lock.sc.old.backup
    fi
    cp ${PWD}/lock.sc.old ${PWD}/lock.sc.old.backup
    rm -rf ${PWD}/lock.sc.old
    cp ${PWD}/lock.sc.new ${PWD}/lock.sc.old
    rm -rf ${PWD}/lock.sc.new
    touch ${PWD}/lock.sc.new
else
    # 第一次使用才会出现这种情况
    cp ${PWD}/lock.sc.new ${PWD}/lock.sc.old
    rm -rf ${PWD}/lock.sc.new
    touch ${PWD}/lock.sc.new
fi
# 生成新列表
find ${Media_DIR} -type f -printf "%TY-%Tm-%Td_%TH:%TM:%TS_%Tz  %p\n" > ${PWD}/lock.sc.new
if [ $? -eq 0 ]; then
    echo -e "${Green}文件遍历成功${Font}"
else
    echo -e "${Red}文件遍历失败${Font}"
    exit 1
fi
# 进行比对
diff ${PWD}/lock.sc.new ${PWD}/lock.sc.old > ${PWD}/lock.sc.cp
# 输出修改结果
grep '<' ${PWD}/lock.sc.cp |awk '{$1=$2="";print}' > lock.sc.end
sed -i 's/  //g' lock.sc.end
}

# 全部重设权限
check_all_file(){
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
    # 设置文件权限
    chmod ${CFVR} ${Media_DIR}
    if [ $? -eq 0 ]; then
        echo -e "${Green}chmod 成功${Font}"
    else
        echo -e "${Red}chomd 失败${Font}"
        exit 1
    fi
    # 设置文件用户和用户组
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
check_change_file(){
if [ ! -f ${PWD}/lock.sc ]; then
    touch ${PWD}/lock.sc
fi
# 获取旧文件列表hash
file_hash_old=$(cat ${PWD}/lock.sc)
find ${Media_DIR} -type f | sha256sum > ${PWD}/lock.sc
# 获取旧文件夹列表hash
dir_hash_old=$(cat ${PWD}/lock.sd)
find ${Media_DIR} -type d | sha256sum > ${PWD}/lock.sd
# 获取新文件列表hash
file_hash_new=$(cat ${PWD}/lock.sc)
dir_hash_new=$(cat ${PWD}/lock.sd)
# 对比
if [[ "$dir_hash_old" != "$dir_hash_new" ]]; then
    # hash不同
    echo -e "${Blue}检测到新文件夹，设置权限中...${Font}"
    # 获取需要重设权限的文件列表
    check_dir_time
    if grep -q '<' ${PWD}/lock.sd.cp; then
        # 设置文件权限
        IFS=$(echo -en "\n\b")
        chmod ${CFVR} $(cat lock.sd.end)
        if [ $? -eq 0 ]; then
            echo -e "${Green}chmod dir 成功${Font}"
        else
            echo -e "${Red}chmod dir 失败${Font}"
            exit 1
        fi
        # 设置文件用户和用户组
        chown ${PUID}:${PGID} $(cat lock.sd.end)
        if [ $? -eq 0 ]; then
            echo -e "${Green}chown dir 成功${Font}"
        else
            echo -e "${Red}chown dir 失败${Font}"
            exit 1
        fi
        IFS=$SAVEIFS
    else
        echo -e "${Blue}文件夹无需设置${Font}"
    fi
else
    # hash相同
    echo -e "${Blue}文件夹无需设置${Font}"
fi

if [[ "$file_hash_old" != "$file_hash_new" ]]; then
    # hash不同
    echo -e "${Blue}检测到新文件，设置权限中...${Font}"
    # 获取需要重设权限的文件列表
    check_file_time
    if grep -q '<' ${PWD}/lock.sc.cp; then
        # 设置文件权限
        IFS=$(echo -en "\n\b")
        chmod ${CFVR} $(cat lock.sc.end)
        if [ $? -eq 0 ]; then
            echo -e "${Green}chmod file 成功${Font}"
        else
            echo -e "${Red}chmod file 失败${Font}"
            exit 1
        fi
        # 设置文件用户和用户组
        chown ${PUID}:${PGID} $(cat lock.sc.end)
        if [ $? -eq 0 ]; then
            echo -e "${Green}chown file 成功${Font}"
        else
            echo -e "${Red}chown file 失败${Font}"
            exit 1
        fi
        IFS=$SAVEIFS
    else
        echo -e "${Blue}文件无需设置${Font}"
    fi
else
    # hash相同
    echo -e "${Blue}文件无需设置${Font}"
fi
}

check_change_file
