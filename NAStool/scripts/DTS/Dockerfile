FROM alpine:3.18

ENV LANG=C.UTF-8 \
    TZ="Asia/Shanghai" \
    PS1="\[\e[32m\][\[\e[m\]\[\e[36m\]\u \[\e[m\]\[\e[37m\]@ \[\e[m\]\[\e[34m\]\h\[\e[m\]\[\e[32m\]]\[\e[m\] \[\e[37;35m\]in\[\e[m\] \[\e[33m\]\w\[\e[m\] \[\e[32m\][\[\e[m\]\[\e[37m\]\d\[\e[m\] \[\e[m\]\[\e[37m\]\t\[\e[m\]\[\e[32m\]]\[\e[m\] \n\[\e[1;31m\]$ \[\e[0m\]" \
    CRON="30 */2 * * *" \
    WEB_URL="http://nastools.cn" \
    API_KEY="xxxxxxxxxxxxxxxx"

RUN apk add --no-cache \
        bash \
        curl \
        tzdata \
    && rm -rf /tmp/* /root/.cache /var/cache/apk/*

COPY --chmod=755 DTS.sh /DTS.sh

ENTRYPOINT [ "/DTS.sh" ]