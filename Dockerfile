FROM alpine:edge
MAINTAINER Wu Di <osiriswd@gmail.com>
RUN apk update && apk add nginx nginx-mod-http-lua curl lua-cjson gettext lua5.1-cjson && mkdir /run/nginx
COPY nginx.conf /etc/nginx/
COPY 404.html /var/lib/nginx/html/
COPY default.conf.template /etc/nginx/conf.d/
COPY thor /etc/nginx/thor
COPY run.sh /usr/local/bin/run.sh
EXPOSE 80
CMD ["run.sh"]
