FROM debian:bookworm

RUN apt update && apt install -y nginx openssl  && apt clean

COPY "tools/nginx.sh" "/usr/local/bin/"
COPY "conf/nginx.conf" "/etc/nginx/conf.d"

RUN rm -f /etc/nginx/sites-enabled/default
RUN chmod +x "/usr/local/bin/nginx.sh"

EXPOSE 443

ENTRYPOINT [ "/usr/local/bin/nginx.sh" ]