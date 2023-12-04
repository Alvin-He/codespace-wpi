#!/usr/bin/bash

(/api/web_gateway)&

exec bash -c "/docker-entrypoint.sh nginx -g 'daemon off;'"