#!/bin/sh
envsubst '$KUBERNETES_SERVICE_HOST $KUBERNETES_SERVICE_PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf
nginx

