# 已经弃用，官方推出目录定时同步插件
# DTS —— NAStool目录定时同步

## Docker

```bash
docker run -d \
    --name=dts \
    -e CRON="30 */2 * * *" \
    -e WEB_URL="http://nastools.cn" \
    -e API_KEY="xxxxxxxxxxxxxxxx" \
    -e TZ="Asia/Shanghai"
    --net=host \
    ddsderek/videolab-dts:latest
```

```yaml
version: '3.3'
services:
    videolab-dts:
        container_name: dts
        environment:
            - 'TZ=Asia/Shanghai'
            - 'CRON=30 */2 * * *'
            - 'WEB_URL=http://nastools.cn'
            - 'API_KEY=xxxxxxxxxxxxxxxx'
        network_mode: host
        image: 'ddsderek/videolab-dts:latest'
```

`-e TZ=Asia/Shanghai` 时区设置

`-e CRON="30 */2 * * *"` 定时执行时间，使用cron表达式

`-e WEB_URL="http://nastools.cn"` NAStool 地址（http/https 一定要加）

`-e API_KEY="xxxxxxxxxxxxxxxx"` NAStool API Key

## Linux

```bash
wget --no-check-certificate https://ddsrem.com/dts-linux -O DTS-Linux.sh && bash DTS-Linux.sh && rm DTS-Linux.sh
```