#!/usr/bin/env bash

NASTOOLS_URL=
API_KEY=

curl -X "GET" \
  "${NASTOOLS_URL}/api/v1/service/sync" \
  -H "accept: application/json" \
  -H "Authorization: ${API_KEY}"
