FROM debian:bookworm

RUN apt update && apt install -y \
	php8.2-fpm \
	php8.2-mysql \
	php8.2-redis \
	curl \
	mariadb-client \
	&& apt clean

COPY "tools/wordpress.sh" "/usr/local/bin"

RUN chmod +x "/usr/local/bin/wordpress.sh"

EXPOSE 9000

ENTRYPOINT [ "/usr/local/bin/wordpress.sh" ]