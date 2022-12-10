#!/bin/bash

mkdir -p /.local
mkdir -p /.pm2
chown -R ${PUID}:${PGID} ${WORKDIR} /config /usr/lib/chromium /.local /.pm2
export PATH=$PATH:/usr/lib/chromium
umask ${UMASK}
exec gosu ${PUID}:${PGID} pm2-runtime start run.py -n NAStool --interpreter python3