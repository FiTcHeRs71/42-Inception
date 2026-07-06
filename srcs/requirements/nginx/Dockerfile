FROM debian:bookworm

RUN apt update && apt install -y nginx openssl  && apt clean

COPY "tools/nginx.sh" "/usr/local/bin/"

RUN chmod +x "/usr/local/bin/nginx.sh"

EXPOSE 443

ENTRYPOINT [ "/usr/local/bin/nginx.sh" ]