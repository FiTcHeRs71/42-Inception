FROM debian:bookworm

RUN apt update  && apt install -y mariadb-server && apt clean 

COPY "tools/mariadb.sh" "/usr/local/bin"

RUN chmod +x "/usr/local/bin/mariadb.sh"

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/mariadb.sh"]