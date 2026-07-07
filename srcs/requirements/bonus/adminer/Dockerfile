FROM debian:bookworm

RUN apt update && apt install -y php8.2-cli php8.2-mysqli wget && apt clean
RUN mkdir -p /var/www/html && \
	wget -O /var/www/html/index.php https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php


COPY "tools/adminer.sh" "/usr/local/bin"

RUN chmod +x "/usr/local/bin/adminer.sh"

EXPOSE 8080

ENTRYPOINT [ "/usr/local/bin/adminer.sh" ]