FROM debian:bookworm

RUN apt update && apt install -y redis-server && apt clean

COPY "tools/redis.sh" "/usr/local/bin"

RUN chmod +x "/usr/local/bin/redis.sh"

EXPOSE 6379

ENTRYPOINT [ "/usr/local/bin/redis.sh" ]