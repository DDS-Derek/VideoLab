FROM ubuntu:22.04

ENV LANG="C.UTF-8" \
    TZ="Asia/Shanghai" \
    NASTOOL_CONFIG="/config/config.yaml" \
    NASTOOL_AUTO_UPDATE=true \
    PS1="\u@\h:\w \$ " \
    REPO_URL="https://github.com/jxxghp/nas-tools.git" \
    PUID=0 \
    PGID=0 \
    UMASK=000 \
    WORKDIR="/nas-tools"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install libffi-dev -y \
    && apt-get install git gcc musl-dev python3-dev python3 libxml2-dev libxslt-dev tzdata zip curl bash fuse inotify-tools xvfb npm python3-pip gosu -y \
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && curl https://rclone.org/install.sh | bash \
    && curl https://dl.min.io/client/mc/release/linux-amd64/mc --create-dirs -o /usr/bin/mc \
    && chmod +x /usr/bin/mc \
    && pip install --upgrade pip setuptools wheel \
    && pip install -r https://raw.githubusercontent.com/jxxghp/nas-tools/master/requirements.txt \
    && npm install pm2 -g \
    && rm -rf /tmp/* /root/.cache

WORKDIR ${WORKDIR}

RUN python_ver=$(python3 -V | awk '{print $2}') \
    && echo 'fs.inotify.max_user_watches=524288' >> /etc/sysctl.conf \
    && echo 'fs.inotify.max_user_instances=524288' >> /etc/sysctl.conf \
    && git config --global pull.ff only \
    && git clone -b master ${REPO_URL} ${WORKDIR} --recurse-submodule \
    && git config --global --add safe.directory ${WORKDIR}

RUN apt-get install libxss1 libappindicator1 libindicator7 wget unzip -y \
    && wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get install -f -y \
    && apt-get install libnss3 libgbm1 libasound2 fonts-liberation -y \
    && dpkg -i google-chrome*.deb \
    && rm -rf  google-chrome*.deb \
    && apt-get install -f -y \
    && wget https://chromedriver.storage.googleapis.com/108.0.5359.71/chromedriver_linux64.zip \
    && unzip chromedriver_linux64.zip \
    && mv -f chromedriver /usr/local/share/chromedriver \
    && mkdir -p /usr/lib/chromium \
    && ln -s /usr/local/share/chromedriver /usr/lib/chromium/chromedriver

COPY --chmod=755 entrypoint.sh /nas-tools/docker/entrypoint.sh

EXPOSE 3000

VOLUME ["/config"]

ENTRYPOINT ["/nas-tools/docker/entrypoint.sh"]