# VideoLab

```bash
bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/DDS-Derek/VideoLab/master/nas-tools-all-in-one/install.sh')
```
```bash
bash <(curl https://ghproxy.com/https://raw.githubusercontent.com/DDS-Derek/VideoLab/master/nas-tools-all-in-one/install.sh)
```
```bash
curl -o install.sh https://ghproxy.com/https://raw.githubusercontent.com/DDS-Derek/VideoLab/master/nas-tools-all-in-one/install.sh && bash install.sh && rm install.sh
```

- 向导安装

  - 1. 环境检测

    - 系统版本
    - 是否为root用户
    - 软件包
      - Docker
      - wget
      - zip
      - curl

  - 2. 获取相关变量

    - PUID/PGID
    - Umask
    - TZ
    - 安装目录
    - 下载目录（可以设置多个）

  - 3. NAStool 安装

       获取信息

    - username
    - password
    - port

  - 4. 下载器安装（可以设置多个）

    - qbittorrent
    - transmission
    - aria2 + ariang

  - 5. 媒体播放器安装（可以设置多个）

    - plex
    - emby
    - jellyfin

- 手动安装
   - 自己选择以上所有功能
- 退出


# idea

- 我准备是把下载器和nastools直接在脚本运行时就连接完成，这样就省点一些小白不知道下载目录和下载器该如何设置了

- 媒体播放器我最多设置好地址，api key还是要自己获取

- 有时间我去把这些下载器的镜像改一改，让它可以完美适配这个脚本和nastools

- 🤣可以考虑再加一个限制容器内存。之前小鸡踩过的坑

- https://www.ztianzeng.com/posts/从Emby直链初识NJS模块/

- 我准备把ChineseSubFinder的安装也加入脚本，虽然目前ChineseSubFinder也不是很好用
