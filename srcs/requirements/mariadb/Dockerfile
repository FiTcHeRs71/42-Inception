FROM debian:bookworm

RUN apt update && apt install -y mariadb-server && apt clean 

COPY "tools/mariadb.sh" "/usr/local/bin"
COPY "conf/99-custom.cnf" "/etc/mysql/mariadb.conf.d/"

RUN chmod +x "/usr/local/bin/mariadb.sh"

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/mariadb.sh"]