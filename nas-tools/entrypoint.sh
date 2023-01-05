#!/bin/bash

mkdir -p /.local
mkdir -p /.pm2
chown -R ${PUID}:${PGID} ${WORKDIR} /config /.local /.pm2
umask ${UMASK}
exec gosu ${PUID}:${PGID} pm2-runtime start run.py -n NAStool --interpreter python3