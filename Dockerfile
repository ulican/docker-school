FROM alpine:3.20

RUN apk add --no-cache nginx curl

COPY app/nginx.conf /etc/nginx/nginx.conf
COPY app/index.html /usr/share/nginx/html/index.html
COPY app/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]