#!/bin/bash

crontab -r
(echo "${CRON} curl -X 'GET' '${WEB_URL}/api/v1/sync/run' -H 'accept: application/json' -H 'Authorization: ${API_KEY}'") | crontab -
crontab -l
exec crond -f
