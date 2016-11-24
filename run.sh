#!/bin/sh

if [ -z "$CONSUL_ADDR" ]
then
    echo "CONSUL_ADDR must be set"
    exit 1;
fi;

CONSUL_PORT=${CONSUL_PORT:-8500}

exec nginx -g "daemon off;" & consul-template -consul="$CONSUL_ADDR:$CONSUL_PORT" -template="/app/nginx.ctmpl:/etc/nginx/conf.d/default.conf:nginx -s reload"
