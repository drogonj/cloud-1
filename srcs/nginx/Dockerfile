FROM nginx:1.27-alpine-slim

RUN apk update && apk add openssl && \
    mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -out /etc/nginx/ssl/cloud1.crt -keyout /etc/nginx/ssl/cloud1.key -subj "/C=FR/ST=IDF/L=Mulhouse/O=42/OU=42/UID=ngalzand"

COPY ./cloud1.conf /etc/nginx/conf.d/default.conf
